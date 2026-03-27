# OpenVPN 성능 최적화 설정 가이드

## 목차
1. [현재 설정 분석](#현재-설정-분석)
2. [설정 상세 설명](#설정-상세-설명)
3. [서버 스펙별 권장 설정](#서버-스펙별-권장-설정)
4. [추가 성능 최적화](#추가-성능-최적화-설정)

---

## 현재 설정 분석

```conf
tcp-nodelay           # ✅ TCP Nagle 알고리즘 비활성화 (지연 감소)
txqueuelen 5000       # ✅ 큐 길이 5000 (기존 1000에서 상향)
tun-mtu-extra 32      # ✅ MTU 여유 공간
sndbuf 4194304        # ✅ 송신 버퍼 4MB (기존 384KB에서 10x 상향)
rcvbuf 4194304        # ✅ 수신 버퍼 4MB (기존 384KB에서 10x 상향)
```

**현재 설정 평가**: 중간~고부하 환경에 적합한 설정입니다.

---

## 설정 상세 설명

### 1. 프로토콜 설정

#### `proto tcp` vs `proto udp`

```conf
proto tcp
```

**설명**: 전송 프로토콜을 TCP로 설정합니다.

**TCP의 특징**:
- ✅ **장점**
  - 신뢰성 보장 (패킷 재전송)
  - 방화벽 통과 용이 (포트 443 사용 시 HTTPS로 위장 가능)
  - 순서 보장
  
- ❌ **단점**
  - **이중 재전송 문제**: VPN 터널 내부와 외부에서 각각 재전송 발생
    ```
    앱 → TCP → OpenVPN TCP → 네트워크 → OpenVPN TCP → 앱
         ↑재전송1        ↑재전송2
    ```
  - 큐 적체 (output saturation) 문제 발생
  - Head-of-line blocking (하나의 패킷 손실이 전체 스트림 지연)
  - 약 10~30% 성능 저하

**UDP의 특징**:
- ✅ **장점**
  - 빠른 속도 (재전송 오버헤드 없음)
  - 큐 적체 없음
  - 실시간 트래픽에 유리 (VoIP, 스트리밍)
  - 약 20~30% 처리량 향상
  
- ❌ **단점**
  - 일부 네트워크/방화벽에서 차단
  - 패킷 순서 보장 안 됨 (OpenVPN 내부에서 처리)

**권장**:
- 소규모(100명 미만): TCP/UDP 둘 다 가능
- 중대규모(100명 이상): **UDP 강력 권장**

---

### 2. TCP 최적화 설정

#### `tcp-nodelay`

```conf
tcp-nodelay
```

**설명**: TCP의 Nagle 알고리즘을 비활성화합니다.

**Nagle 알고리즘이란?**:
- 작은 패킷들을 모아서 한번에 전송하는 기법
- 네트워크 효율성 향상 목적
- 하지만 **지연(latency) 증가** 발생

**동작 원리**:
```
Nagle 활성화 (기본):
  작은 패킷 1 → 대기
  작은 패킷 2 → 대기  
  작은 패킷 3 → 대기
  [200ms 후] → 한번에 전송

tcp-nodelay 활성화:
  작은 패킷 1 → 즉시 전송
  작은 패킷 2 → 즉시 전송
  작은 패킷 3 → 즉시 전송
```

**효과**:
- VPN 응답 시간 30~50% 개선
- SSH, RDP 등 대화형 세션 체감 속도 향상
- 대용량 파일 전송은 큰 차이 없음

**권장**: proto tcp 사용 시 **반드시 활성화**

---

### 3. 큐 관리

#### `txqueuelen`

```conf
txqueuelen 5000
```

**설명**: tun0 네트워크 인터페이스의 송신 큐 길이를 설정합니다.

**큐란?**:
```
[앱 데이터] → [OpenVPN] → [tun0 큐] → [물리 NIC] → 네트워크
                              ↑
                         여기 길이 설정
```

**동작 원리**:
- 패킷이 물리 NIC로 전송되기 전 대기하는 버퍼
- 큐가 가득 차면 패킷 드롭 발생 → output saturation
- 기본값: 500 (너무 작음)

**값 선택 기준**:
```
100명 미만:   3000
100~500명:    5000  ← 현재 설정
500~1000명:   10000
1000명 이상:  15000
```

**주의사항**:
- 너무 크면: 메모리 사용량 증가, 지연 증가 (bufferbloat)
- 너무 작으면: 패킷 드롭 증가, output saturation

**실시간 확인**:
```bash
ip link show tun0 | grep qlen
# qlen 5000 확인
```

---

### 4. MTU 설정

#### `tun-mtu`

```conf
tun-mtu 1400
```

**설명**: VPN 터널의 Maximum Transmission Unit (최대 전송 단위)를 설정합니다.

**MTU란?**:
- 한 번에 전송할 수 있는 최대 패킷 크기
- 이더넷 표준: 1500 bytes

**VPN에서 MTU가 작아지는 이유**:
```
원본 패킷: 1500 bytes
  ↓
OpenVPN 암호화 헤더 추가: +100~140 bytes
  ↓
총 크기: 1600~1640 bytes → 이더넷 MTU(1500) 초과!
  ↓
Fragmentation (조각화) 발생 → 성능 저하
```

**해결책**:
```conf
tun-mtu 1400  # VPN 내부 패킷을 1400으로 제한
  ↓
+암호화 헤더 140 bytes
  ↓
= 1540 bytes (이더넷 MTU 이내)
```

**값 선택**:
- `1400`: 안전한 기본값 (대부분 환경)
- `1500`: 이상적이지만 일부 환경에서 fragmentation
- `1280`: PPPoE/ADSL 등 MTU가 작은 환경
- `9000`: Jumbo Frame 지원 환경 (데이터센터)

**확인 방법**:
```bash
# 클라이언트에서 MTU 테스트
ping -M do -s 1372 <server_ip>  # 1372 + 28 (ICMP header) = 1400
```

---

#### `mssfix`

```conf
mssfix 1360
```

**설명**: TCP Maximum Segment Size를 조정하여 fragmentation을 방지합니다.

**MSS란?**:
- TCP 데이터 페이로드의 최대 크기
- MTU - IP header(20) - TCP header(20) = MSS

**동작 원리**:
```
기본 MSS: 1460 (MTU 1500 기준)
  ↓
VPN 암호화 헤더: +140
  ↓
실제 전송 크기: 1600 → Fragmentation!

mssfix 1360 설정:
  ↓
강제로 MSS를 1360으로 제한
  ↓
+IP/TCP header(40) + VPN header(140) = 1540
  ↓
Fragmentation 방지
```

**계산 공식**:
```
mssfix = tun-mtu - 40 (IP+TCP header)
mssfix = 1400 - 40 = 1360
```

**proto udp 사용 시**:
```conf
mssfix 0  # UDP는 mssfix 불필요
```

---

#### `tun-mtu-extra`

```conf
tun-mtu-extra 32
```

**설명**: 암호화 헤더를 위한 추가 공간을 미리 확보합니다.

**동작 원리**:
```
tun-mtu-extra 없으면:
  패킷 1400 bytes → 암호화 → 1540 bytes
  → 버퍼 재할당 필요 → 메모리 복사 오버헤드

tun-mtu-extra 32:
  처음부터 1400 + 32 = 1432 bytes 버퍼 할당
  → 암호화 시 버퍼 재할당 불필요
  → 성능 향상 (약 5~10%)
```

**권장값**: 32 (대부분 암호화 헤더 크기)

---

### 5. 버퍼 설정

#### `sndbuf` (송신 버퍼)

```conf
sndbuf 4194304  # 4MB
```

**설명**: OpenVPN 프로세스의 **클라이언트별** 송신 버퍼 크기를 설정합니다.

**버퍼의 역할**:
```
서버 앱 → OpenVPN → [sndbuf 큐] → 네트워크 스택 → 클라이언트
                      ↑
                  여기가 4MB
```

**왜 중요한가?**:
- 클라이언트 수신 속도가 느릴 때 패킷이 이 버퍼에 대기
- 버퍼가 작으면 → 즉시 포화 → **output saturation**
- 버퍼가 크면 → 일시적인 속도 저하 흡수

**현재 문제와의 관계**:
```
Android 백그라운드 → window 4KB로 축소
  ↓
서버가 보내는 패킷이 sndbuf에 적체
  ↓
sndbuf 384KB (기본값) → 즉시 포화
  ↓
output saturation 발생

sndbuf 4MB로 상향:
  ↓
일시적인 속도 저하를 버퍼가 흡수
  ↓
saturation 빈도 감소
```

**값 선택 기준**:
```
동시 접속자 | sndbuf (클라이언트별)
-----------+----------------------
100명 미만  | 2MB (2097152)
100~500명  | 4MB (4194304) ← 현재
500명 이상  | 8MB (8388608)
```

**메모리 계산**:
- 100명 × 4MB = 400MB
- 500명 × 4MB = 2GB
- 서버 메모리 충분한지 확인 필요

**주의사항**:
- 너무 크면: 메모리 부족, 지연 증가
- 너무 작으면: output saturation 빈번

---

#### `rcvbuf` (수신 버퍼)

```conf
rcvbuf 4194304  # 4MB
```

**설명**: OpenVPN 프로세스의 **클라이언트별** 수신 버퍼 크기를 설정합니다.

**버퍼의 역할**:
```
클라이언트 → 네트워크 스택 → [rcvbuf 큐] → OpenVPN → 서버 앱
                                ↑
                            여기가 4MB
```

**동작 원리**:
- 클라이언트에서 올라오는 패킷을 임시 저장
- OpenVPN이 처리 속도가 느릴 때 버퍼링
- 일반적으로 sndbuf보다 덜 중요 (업로드 < 다운로드)

**권장**: sndbuf와 동일한 크기 설정

---

#### 클라이언트 버퍼 푸시

```conf
push "sndbuf 1048576"  # 클라이언트 송신 1MB
push "rcvbuf 1048576"  # 클라이언트 수신 1MB
```

**설명**: 서버가 클라이언트에게 버퍼 크기를 지시합니다.

**왜 서버보다 작은가?**:
```
서버: 35명 × 4MB = 140MB
  ↓
각 클라이언트: 1명 × 1MB = 1MB

서버는 여러 클라이언트를 처리하므로 큰 버퍼 필요
클라이언트는 한 연결만 처리하므로 작은 버퍼로 충분
```

**모바일 디바이스 고려**:
- Android/iOS는 메모리 제한적
- 너무 큰 버퍼 → 앱 강제 종료
- 1~2MB가 적절

---

### 6. 압축 설정

#### `compress`

```conf
compress stub-v2
```

**설명**: 데이터 압축 방식을 설정합니다.

**옵션**:

1. **`stub-v2`** (압축 비활성화) ← **권장**
   ```
   원본 데이터 → 압축 안 함 → 전송
   
   ✅ CPU 사용량 최소
   ✅ 지연 시간 최소
   ❌ 트래픽 감소 없음
   ```

2. **`lz4-v2`** (빠른 압축)
   ```
   원본 데이터 → LZ4 압축 → 전송
   
   ✅ 압축률 30~50%
   ✅ CPU 오버헤드 낮음
   ❌ CPU 사용 증가
   ```

3. **`lzo`** (구형, 비권장)
   ```
   원본 데이터 → LZO 압축 → 전송
   
   ❌ lz4보다 느림
   ❌ 보안 취약점 가능성
   ```

**선택 기준**:
```
상황                    | 권장
-----------------------+-----------
일반적인 경우          | stub-v2
대역폭 제한 (종량제)   | lz4-v2
CPU 부하 이미 높음     | stub-v2
```

**성능 영향**:
- stub-v2: 0% CPU 오버헤드
- lz4-v2: 10~20% CPU 증가
- 압축으로 인한 지연: 5~15ms

**주의**: 클라이언트도 동일 설정 필요
```conf
push "compress stub-v2"
```

---

### 7. 암호화 설정

#### `data-ciphers`

```conf
data-ciphers AES-128-GCM:AES-256-GCM:CHACHA20-POLY1305
```

**설명**: 데이터 채널 암호화 알고리즘을 우선순위 순으로 지정합니다.

**알고리즘 비교**:

| 알고리즘 | 속도 | 보안성 | CPU 부하 | 비고 |
|---------|------|--------|---------|------|
| **AES-128-GCM** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 낮음 | AES-NI 필요 |
| AES-256-GCM | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 중간 | AES-NI 필요 |
| CHACHA20-POLY1305 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 낮음 | ARM/모바일 최적 |
| AES-256-CBC | ⭐⭐⭐ | ⭐⭐⭐⭐ | 높음 | 구형 |

**AES-NI란?**:
- Intel/AMD CPU의 하드웨어 암호화 가속 기능
- AES 암호화를 CPU 명령어로 처리
- 약 5~10배 속도 향상

**확인 방법**:
```bash
grep -m1 aes /proc/cpuinfo
# flags 에 aes 있으면 AES-NI 지원
```

**권장 설정**:
```conf
# AES-NI 지원 서버 (Intel/AMD)
data-ciphers AES-128-GCM:AES-256-GCM

# AES-NI 미지원 또는 ARM 서버
data-ciphers CHACHA20-POLY1305:AES-128-GCM
```

**AES-128 vs AES-256**:
```
AES-128-GCM:
  ✅ 약 30% 빠름
  ✅ 보안성 충분 (2^128 = 수천 년 크래킹 필요)
  ✅ 권장

AES-256-GCM:
  ✅ 최고 보안성
  ❌ 느림
  금융/군사 등 극도의 보안 필요 시
```

**성능 벤치마크** (100MB 전송 시간):
```
AES-128-GCM:         0.8초
AES-256-GCM:         1.1초 (+37%)
CHACHA20-POLY1305:   0.9초 (+12%)
AES-256-CBC:         2.3초 (+187%)
```

---

#### `auth`

```conf
auth SHA256
```

**설명**: HMAC 인증 해시 알고리즘을 설정합니다.

**역할**:
- 패킷 무결성 검증
- 변조 방지

**옵션 비교**:

| 알고리즘 | 속도 | 보안성 | CPU 부하 |
|---------|------|--------|---------|
| **SHA256** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 낮음 |
| SHA384 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 중간 |
| SHA512 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 높음 |

**권장**: SHA256 (속도와 보안 균형)

**주의**: GCM 모드는 자체 인증 포함
```conf
data-ciphers AES-128-GCM  # GCM이 인증 포함
auth SHA256               # 추가 인증 (이중 검증)
```

---

#### `tls-ciphersuites`

```conf
tls-ciphersuites TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256
```

**설명**: TLS 1.3 제어 채널 암호화 스위트를 설정합니다.

**제어 채널 vs 데이터 채널**:
```
제어 채널 (TLS):
  - 초기 연결 설정
  - 키 교환
  - 인증
  → tls-ciphersuites 적용

데이터 채널:
  - 실제 VPN 트래픽
  → data-ciphers 적용
```

**권장**: 데이터 채널과 동일한 알고리즘 사용

---

### 8. 연결 관리

#### `keepalive`

```conf
keepalive 10 120
```

**설명**: 연결 유지 및 타임아웃 설정입니다.

**형식**: `keepalive <ping_interval> <timeout>`

**동작 원리**:
```
10초마다 ping 전송
  ↓
응답 없음 카운트
  ↓
120초 동안 응답 없으면
  ↓
연결 종료 및 재연결 시도
```

**프로토콜별 권장값**:
```conf
# TCP
keepalive 10 60   # 짧게 설정 (TCP는 자체 재전송 있음)

# UDP
keepalive 10 120  # 길게 설정 (UDP는 패킷 loss 가능)
```

**NAT 환경 고려**:
- NAT 테이블 타임아웃: 보통 60~300초
- keepalive를 NAT 타임아웃보다 짧게 설정
- 예: NAT 120초면 → keepalive 10 60

---

#### `ping-timer-rem`

```conf
ping-timer-rem
```

**설명**: 재연결 시 클라이언트의 ping 타이머를 리셋합니다.

**문제 상황**:
```
클라이언트가 재연결 시도
  ↓
기존 ping 타이머가 계속 동작
  ↓
타이머 만료 → 즉시 연결 종료
  ↓
무한 재연결 루프
```

**해결**:
```conf
ping-timer-rem  # 재연결 시 타이머 리셋
```

**권장**: 불안정한 네트워크 환경에서 활성화

---

#### `persist-key` / `persist-tun`

```conf
persist-key
persist-tun
```

**설명**: 재연결 시 키와 tun 인터페이스를 유지합니다.

**동작**:
```
persist-key 없으면:
  재연결 → 키 재생성 → 초기화 지연

persist-key 있으면:
  재연결 → 기존 키 유지 → 빠른 재연결

persist-tun 없으면:
  재연결 → tun0 삭제 후 재생성 → 라우팅 초기화

persist-tun 있으면:
  재연결 → tun0 유지 → 라우팅 유지
```

**효과**:
- 재연결 시간 50% 단축 (10초 → 5초)
- 라우팅 테이블 유지
- 앱 연결 끊김 최소화

**권장**: **항상 활성화**

---

### 9. 성능 최적화

#### `fast-io`

```conf
fast-io
```

**설명**: 논블로킹(non-blocking) I/O를 활성화합니다.

**블로킹 vs 논블로킹**:
```
블로킹 I/O (기본):
  패킷 읽기 시도 → 패킷 없으면 대기 → CPU idle
  ↓
  한 번에 한 클라이언트만 처리

논블로킹 I/O (fast-io):
  패킷 읽기 시도 → 없으면 즉시 다음 클라이언트
  ↓
  여러 클라이언트 빠르게 순회
```

**효과**:
- 다중 클라이언트 처리 속도 향상
- CPU 활용도 증가
- 약 10~20% 처리량 향상

**주의**:
```conf
# proto udp 에서만 효과적
proto udp
fast-io

# proto tcp 에서는 효과 미미
```

**권장**: proto udp + 다중 클라이언트 환경에서 활성화

---

#### `explicit-exit-notify`

```conf
explicit-exit-notify 1
```

**설명**: 클라이언트가 종료 시 서버에 명시적으로 알립니다.

**동작**:
```
클라이언트 종료
  ↓
서버에 DISCONNECT 메시지 전송
  ↓
서버가 즉시 세션 정리
  ↓
IP 즉시 재사용 가능

없으면:
  클라이언트 종료
  ↓
  서버는 모름
  ↓
  keepalive 타임아웃(120초) 후 정리
  ↓
  IP가 120초간 잠김
```

**효과**:
- IP pool 효율성 향상
- 재연결 속도 향상
- 좀비 세션 방지

**프로토콜**:
```conf
# UDP만 지원
proto udp
explicit-exit-notify 1

# TCP는 사용 불가 (TCP는 FIN 패킷으로 알림)
```

**권장**: proto udp 사용 시 활성화

---

### 10. IP 할당 관리

#### `ifconfig-pool-persist`

```conf
ifconfig-pool-persist /var/log/openvpn-ipp.txt
```

**설명**: 클라이언트별 IP 할당 정보를 파일에 저장합니다.

**파일 형식**:
```
# /var/log/openvpn-ipp.txt
user1,172.26.0.10
user2,172.26.0.11
user3,172.26.0.12
```

**동작**:
```
없으면:
  user1 접속 → 172.26.0.10 할당
  user1 종료
  user2 접속 → 172.26.0.10 할당 (같은 IP 재사용)
  user1 재접속 → 172.26.0.11 할당 (다른 IP!)
  
있으면:
  user1 접속 → 172.26.0.10 할당 → 파일 저장
  user1 종료
  user1 재접속 → 파일 확인 → 172.26.0.10 재할당
```

**중요성**:
- **IP 중복 할당 방지** ← 가장 중요!
- 방화벽 규칙 유지
- 로그 추적 용이
- 사용자 경험 일관성

**프로그램 오류 시나리오 방지**:
```
ifconfig-pool-persist 없을 때:
  
  user1: 172.26.0.10 사용 중
  서버 재시작
  user2: 172.26.0.10 할당 ← 중복!
  user1: 연결 끊김

ifconfig-pool-persist 있으면:
  
  user1: 172.26.0.10 사용 중 → 파일 저장
  서버 재시작 → 파일 읽기
  user2: 172.26.0.11 할당 ← 안전
  user1: 여전히 172.26.0.10
```

**권장**: **필수 설정**

---

#### `client-config-dir`

```conf
client-config-dir /etc/openvpn/ccd
```

**설명**: 클라이언트별 개별 설정 디렉토리를 지정합니다.

**사용 예**:

**1. 고정 IP 할당**:
```bash
# /etc/openvpn/ccd/user1
ifconfig-push 172.26.0.100 255.255.254.0
```

**2. 문제 클라이언트 속도 제한**:
```bash
# /etc/openvpn/ccd/problem_user
push "sndbuf 524288"   # 버퍼 축소
push "rcvbuf 524288"
```

**3. VIP 클라이언트 우대**:
```bash
# /etc/openvpn/ccd/vip_user
push "sndbuf 8388608"  # 대형 버퍼
push "rcvbuf 8388608"
```

**4. 특정 라우팅 추가**:
```bash
# /etc/openvpn/ccd/dev_user
push "route 10.20.0.0 255.255.0.0"  # 개발 네트워크 접근
```

**동작 순서**:
```
1. server.conf 설정 적용
2. client-config-dir에서 CN 파일 찾기
3. 파일 있으면 추가 설정 적용 (덮어쓰기)
```

**권장 활용**:
- Android 백그라운드 문제 사용자 → 버퍼 확대
- 트래픽 많은 사용자 → 별도 모니터링
- 관리자 계정 → 추가 라우팅 권한

---

### 11. 로그 및 모니터링

#### `verb`

```conf
verb 3
```

**설명**: 로그 상세도 레벨을 설정합니다.

**레벨별 차이**:

| 레벨 | 내용 | 용도 | 성능 영향 |
|------|------|------|-----------|
| 0 | 치명적 오류만 | - | 0% |
| 1 | 오류 + 경고 | 안정 운영 | 1% |
| 2 | + 주요 이벤트 | 일반 운영 | 2% |
| **3** | + 연결/해제 | **권장** | 3% |
| 4 | + 라우팅/설정 | 문제 분석 | 5% |
| 5 | + 패킷 정보 | 디버깅 | 10% |
| 6-11 | + 상세 디버그 | 개발 | 20%+ |

**예시 로그**:

```
verb 1:
  ERROR: TLS handshake failed

verb 3:
  user1 connected from 1.2.3.4
  user1 assigned IP 172.26.0.10
  user1 disconnected

verb 5:
  user1 sent packet seq=12345 len=1400
  user1 received ACK seq=12345
```

**성능 영향**:
```
100명 × verb 5 = 약 5~10% CPU 오버헤드
  ↓
파일 I/O 증가
  ↓
디스크 부하 증가
```

**권장**:
- 일반 운영: **verb 3**
- 문제 발생: verb 4~5 (일시적)
- 안정 후: verb 1~2

---

#### `status`

```conf
status /var/log/openvpn-status.log 10
```

**설명**: 연결 상태를 주기적으로 파일에 기록합니다.

**형식**: `status <파일경로> <갱신주기(초)>`

**파일 내용**:
```
OpenVPN CLIENT LIST
Updated,2026-02-03 14:13:39
Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since
user1,1.2.3.4:12345,1000000,5000000,2026-02-03 10:00:00
user2,5.6.7.8:23456,2000000,8000000,2026-02-03 11:00:00

ROUTING TABLE
Virtual Address,Common Name,Real Address,Last Ref
172.26.0.10,user1,1.2.3.4:12345,2026-02-03 14:13:30
172.26.0.11,user2,5.6.7.8:23456,2026-02-03 14:13:35

GLOBAL STATS
Max bcast/mcast queue length,0
```

**활용**:
```bash
# 현재 연결 수
grep -c "^172.26" /var/log/openvpn-status.log

# 트래픽 상위 사용자
awk -F',' '/^[^#]/ {print $1, $4}' /var/log/openvpn-status.log | sort -k2 -nr

# 중복 IP 확인
awk -F',' '/^172/ {print $1}' /var/log/openvpn-status.log | sort | uniq -d
```

**갱신 주기 선택**:
```
10초:  실시간 모니터링 (권장)
30초:  일반 모니터링
60초:  최소 모니터링
```

**성능 영향**:
- 파일 I/O 매 10초
- 100명 기준: 무시할 수준
- 1000명 기준: 1~2% CPU

---

#### `status-version`

```conf
status-version 3
```

**설명**: status 파일 형식 버전을 설정합니다.

**버전별 차이**:
- Version 1: 기본 정보만
- Version 2: + 가상 IP 추가
- **Version 3**: + 타임스탬프, 통계 추가 ← 권장

**권장**: 3 (가장 상세한 정보)

---

### 12. 보안 설정

#### `tls-version-min`

```conf
tls-version-min 1.3
```

**설명**: 최소 TLS 버전을 강제합니다.

**버전별 특징**:
- TLS 1.0/1.1: 취약점 존재, 비권장
- TLS 1.2: 안전, 호환성 좋음
- **TLS 1.3**: 가장 안전, 빠름 ← 권장

**성능 영향**:
```
TLS 1.2:  핸드셰이크 2-RTT
TLS 1.3:  핸드셰이크 1-RTT
  ↓
연결 속도 50% 향상
```

**호환성**:
- OpenVPN 2.5+ 필요
- 구형 클라이언트는 연결 불가

**권장**:
```conf
# 신규 환경
tls-version-min 1.3

# 구형 클라이언트 있음
tls-version-min 1.2
```

---

### 13. 시스템 리소스

#### `max-clients`

```conf
max-clients 600
```

**설명**: 동시 접속 가능한 최대 클라이언트 수를 제한합니다.

**목적**:
- 서버 과부하 방지
- 리소스 보호
- DoS 공격 방어

**계산 방법**:
```
예상 동시 접속자: 300명
여유율: 2배
  ↓
max-clients = 300 × 2 = 600
```

**메모리 계산**:
```
클라이언트당 메모리:
  - 기본 구조체: ~100KB
  - sndbuf: 4MB
  - rcvbuf: 4MB
  ────────────────
  총 약 8.1MB

600명 × 8.1MB = 약 5GB
  ↓
서버 메모리: 16GB 권장
```

**주의**: 너무 높으면
- 메모리 부족 → OOM Killer
- CPU 과부하
- 서비스 불안정

---

### 14. 고급 최적화

#### `reneg-sec`

```conf
reneg-sec 3600
```

**설명**: 데이터 채널 키 재협상 주기(초)를 설정합니다.

**재협상이란?**:
```
연결 유지 중
  ↓
3600초(1시간)마다
  ↓
새 암호화 키 생성
  ↓
보안 강화
```

**주기 선택**:
```
짧게 (1800초 = 30분):
  ✅ 보안 강화
  ❌ CPU 오버헤드
  ❌ 일시적 지연

길게 (7200초 = 2시간):
  ✅ 성능 우선
  ❌ 키 노출 시간 증가

권장: 3600초 (1시간)
```

---

#### `fragment`

```conf
fragment 1300  # UDP 전용
```

**설명**: UDP 패킷을 특정 크기로 분할합니다.

**사용 상황**:
```
경로 상의 MTU가 작은 경우
  ↓
예: PPPoE(1492), Tunnel(1400)
  ↓
fragment 1300 설정
  ↓
큰 패킷을 1300 bytes로 분할
```

**주의**:
- proto udp만 사용 가능
- 성능 저하 가능 (분할/재조립 오버헤드)
- 가능하면 tun-mtu 조정이 우선

**권장**:
```conf
# 일반적으로 불필요
# fragment 0  

# MTU 문제 있을 때만
fragment 1300
```

---

#### `tcp-queue-limit`

```conf
tcp-queue-limit 256  # TCP 전용
```

**설명**: TCP 연결의 큐 크기를 제한합니다.

**동작**:
```
클라이언트 연결 대기
  ↓
큐에 최대 256개 대기
  ↓
초과하면 연결 거부
```

**목적**:
- SYN Flood 공격 방어
- 리소스 보호

**권장값**:
```
일반: 128
대규모: 256~512
```

---

### 15. 멀티코어 최적화

#### CPU Affinity

```conf
# systemd 서비스 파일에서 설정
# /etc/systemd/system/openvpn@server.service.d/override.conf

[Service]
CPUAffinity=0-3  # CPU 0,1,2,3 사용
```

**설명**: OpenVPN 프로세스를 특정 CPU 코어에 바인딩합니다.

**효과**:
```
CPU 캐시 히트율 향상
  ↓
문맥 전환(Context Switch) 감소
  ↓
약 5~10% 성능 향상
```

**설정 예**:
```
4 Core CPU:
  CPU 0-1: OpenVPN
  CPU 2-3: 시스템/기타

8 Core CPU:
  CPU 0-3: OpenVPN
  CPU 4-7: 시스템/기타
```

---

이것으로 각 설정에 대한 상세 설명이 완료되었습니다.

---

## 서버 스펙별 권장 설정

### 🟢 Tier 1: 동시 접속자 100명 미만
**서버 스펙**: 2 Core CPU, 8GB Memory

```conf
# ===== 프로토콜 및 네트워크 =====
port 4443
proto tcp                    # 또는 udp (udp 권장, 큐 적체 방지)
dev tun
topology subnet

# ===== MTU 설정 =====
tun-mtu 1400                 # 표준값 유지
mssfix 1360                  # MTU - 40
tun-mtu-extra 32             # ✅ 현재 설정 유지

# ===== TCP 최적화 (proto tcp 사용시) =====
tcp-nodelay                  # ✅ 현재 설정 유지
txqueuelen 3000              # 📝 100명 미만: 3000 권장

# ===== 버퍼 설정 =====
sndbuf 2097152               # 📝 2MB (100명 미만: 2MB 충분)
rcvbuf 2097152               # 📝 2MB
push "sndbuf 524288"         # 클라이언트 송신 512KB
push "rcvbuf 524288"         # 클라이언트 수신 512KB

# ===== 연결 관리 =====
keepalive 10 60              # 10초 핑, 60초 타임아웃
persist-key
persist-tun
max-clients 150              # 📝 여유있게 150 설정

# ===== 암호화 최적화 =====
data-ciphers AES-128-GCM:AES-256-GCM:CHACHA20-POLY1305
# AES-128-GCM이 AES-256보다 약 30% 빠름 (보안성도 충분)
auth SHA256                  # SHA512 대신 SHA256 (더 빠름)

# ===== 압축 =====
compress lz4-v2              # 또는 stub-v2 (압축 없음, 더 빠름)
push "compress lz4-v2"

# ===== 성능 모니터링 =====
status /var/log/openvpn-status.log 10
verb 3                       # 일반 운영은 3, 디버깅시에만 4-5
```

**Tier 1 커널 튜닝**:
```bash
# /etc/sysctl.conf
net.core.rmem_default = 2097152
net.core.rmem_max = 8388608
net.core.wmem_default = 2097152
net.core.wmem_max = 8388608
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65536 8388608
net.ipv4.tcp_congestion_control = bbr  # BBR 혼잡 제어
```

---

### 🟡 Tier 2: 동시 접속자 100~500명
**서버 스펙**: 4 Core CPU, 16GB Memory

```conf
# ===== 프로토콜 및 네트워크 =====
port 4443
proto udp                    # ⚠️ UDP 강력 권장 (TCP는 큐 적체 문제)
dev tun
topology subnet

# ===== MTU 설정 =====
tun-mtu 1400
mssfix 0                     # UDP는 mssfix 불필요
tun-mtu-extra 32             # ✅ 현재 설정 유지

# ===== UDP 최적화 =====
txqueuelen 5000              # ✅ 현재 설정 유지
fast-io                      # 📝 논블로킹 I/O 활성화
sndbuf 4194304               # ✅ 4MB - 현재 설정 유지
rcvbuf 4194304               # ✅ 4MB - 현재 설정 유지
push "sndbuf 1048576"        # 클라이언트 1MB
push "rcvbuf 1048576"        # 클라이언트 1MB

# ===== 연결 관리 =====
keepalive 10 120             # UDP는 타임아웃 길게
ping-timer-rem               # 클라이언트 재연결 최적화
persist-key
persist-tun
max-clients 600              # 📝 여유있게 600

# ===== 멀티스레딩 최적화 =====
# OpenVPN 3.x 이상에서 사용 가능
# multihome                  # 멀티 네트워크 인터페이스 지원
# tcp-queue-limit 256        # TCP 큐 제한 (TCP 사용시)

# ===== 암호화 최적화 =====
data-ciphers AES-128-GCM:CHACHA20-POLY1305
# AES-NI 있으면 AES-128-GCM, 없으면 CHACHA20-POLY1305가 빠름
auth SHA256
tls-ciphersuites TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256

# ===== 압축 =====
compress stub-v2             # 📝 압축 비활성화 (CPU 절약)
push "compress stub-v2"

# ===== TLS 최적화 =====
tls-timeout 2                # TLS 협상 타임아웃 단축
reneg-sec 3600               # 재협상 간격 1시간

# ===== 성능 모니터링 =====
status /var/log/openvpn-status.log 10
status-version 3             # 상세 통계
verb 3
```

**Tier 2 커널 튜닝**:
```bash
# /etc/sysctl.conf
net.core.rmem_default = 4194304
net.core.rmem_max = 16777216
net.core.wmem_default = 4194304
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 10000
net.core.somaxconn = 4096
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.ip_local_port_range = 10000 65535
fs.file-max = 100000
```

**시스템 제한 설정**:
```bash
# /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
```

---

### 🔴 Tier 3: 동시 접속자 500명 이상
**서버 스펙**: 8 Core CPU, 32GB Memory

```conf
# ===== 프로토콜 및 네트워크 =====
port 4443
proto udp                    # ⚠️ UDP 필수
dev tun
topology subnet

# ===== MTU 설정 =====
tun-mtu 1500                 # 📝 대규모: 1500 (Jumbo Frame 고려)
fragment 0                   # UDP fragmentation 비활성화
tun-mtu-extra 32

# ===== UDP 최적화 =====
txqueuelen 10000             # 📝 대규모: 10000
fast-io                      # 논블로킹 I/O
sndbuf 8388608               # 📝 8MB (대규모 환경)
rcvbuf 8388608               # 📝 8MB
push "sndbuf 2097152"        # 클라이언트 2MB
push "rcvbuf 2097152"        # 클라이언트 2MB

# ===== 연결 관리 =====
keepalive 10 120
ping-timer-rem
persist-key
persist-tun
max-clients 1000             # 📝 1000명

# ===== 멀티 프로세스 전략 =====
# 단일 프로세스 한계: 약 500-1000 연결
# 해결: 포트별로 여러 OpenVPN 인스턴스 실행
# 
# 예: 4개 인스턴스
# - 4443: 250명
# - 4444: 250명
# - 4445: 250명
# - 4446: 250명
# → 로드밸런서로 분산

# ===== 암호화 최적화 =====
data-ciphers AES-128-GCM:CHACHA20-POLY1305
auth SHA256
tls-ciphersuites TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256
tls-version-min 1.3          # TLS 1.3 강제

# ===== 압축 =====
compress stub-v2             # 압축 비활성화
push "compress stub-v2"

# ===== TLS 최적화 =====
tls-timeout 2
reneg-sec 7200               # 재협상 2시간

# ===== IP 할당 최적화 =====
ifconfig-pool-persist /var/log/ipp.txt
# 📝 IP 재사용으로 pool 효율성 증가

# ===== 성능 모니터링 =====
status /var/log/openvpn-status.log 30  # 30초 간격
status-version 3
verb 3
```

**Tier 3 커널 튜닝**:
```bash
# /etc/sysctl.conf
net.core.rmem_default = 8388608
net.core.rmem_max = 33554432     # 32MB
net.core.wmem_default = 8388608
net.core.wmem_max = 33554432     # 32MB
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 8192
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 65536 33554432
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 8192
fs.file-max = 200000
vm.swappiness = 10               # Swap 최소화
```

**시스템 제한 설정**:
```bash
# /etc/security/limits.conf
* soft nofile 100000
* hard nofile 100000
root soft nofile 100000
root hard nofile 100000

# systemd 서비스 파일 수정
# /etc/systemd/system/openvpn@.service.d/override.conf
[Service]
LimitNOFILE=100000
CPUAffinity=0-7              # CPU 바인딩
Nice=-10                     # 우선순위 상향
```

**멀티 인스턴스 구성** (500명 이상):
```bash
# /etc/openvpn/server1.conf (port 4443)
# /etc/openvpn/server2.conf (port 4444)
# /etc/openvpn/server3.conf (port 4445)
# /etc/openvpn/server4.conf (port 4446)

# 각 인스턴스는 다른 서브넷 사용
# server1: 172.26.0.0/24
# server2: 172.26.1.0/24
# server3: 172.26.2.0/24
# server4: 172.26.3.0/24
```

---

## 추가 성능 최적화 설정

### 1. 프로토콜 선택: TCP vs UDP

```conf
# TCP 장점: 방화벽 통과 쉬움
# TCP 단점: output saturation (현재 문제), 재전송 오버헤드

proto tcp
tcp-nodelay        # TCP 사용시 필수

# UDP 장점: 큐 적체 없음, 더 빠름
# UDP 단점: 일부 네트워크에서 차단

proto udp
explicit-exit-notify 1  # UDP 사용시 권장
```

**권장**: 
- 100명 미만: TCP/UDP 둘 다 가능
- 100명 이상: **UDP 강력 권장**

---

### 2. 암호화 알고리즘 성능 비교

```conf
# 속도 순서 (AES-NI 지원 CPU 기준):
# 1. AES-128-GCM (가장 빠름, 보안 충분)
# 2. AES-256-GCM
# 3. CHACHA20-POLY1305 (AES-NI 없을 때 빠름)

# 권장 설정
data-ciphers AES-128-GCM:AES-256-GCM:CHACHA20-POLY1305
auth SHA256  # SHA256이 SHA512보다 빠름

# CPU에 AES-NI 있는지 확인
grep -m1 aes /proc/cpuinfo
```

---

### 3. 압축 설정

```conf
# 압축 비활성화 권장 (CPU 절약)
compress stub-v2
push "compress stub-v2"

# 압축 활성화 (트래픽 감소, CPU 증가)
compress lz4-v2
push "compress lz4-v2"

# 판단 기준:
# - 대역폭 제한 있음 → lz4-v2
# - CPU 부하 높음 → stub-v2
# - 일반적으로 stub-v2 권장
```

---

### 4. 로그 레벨 최적화

```conf
# 개발/디버깅
verb 5

# 일반 운영 (권장)
verb 3

# 최소 로그 (최고 성능)
verb 1
log /dev/null      # 극단적인 경우

# 권장: verb 3, 문제 발생시에만 verb 4-5
```

---

### 5. ifconfig-pool-persist (중요)

```conf
# 📝 반드시 설정 (IP 중복 할당 방지)
ifconfig-pool-persist /var/log/openvpn-ipp.txt

# 없으면: 재접속마다 랜덤 IP → 충돌 가능
# 있으면: CN별 IP 기억 → 안정적
```

---

### 6. client-config-dir 활용

```conf
client-config-dir /etc/openvpn/ccd

# /etc/openvpn/ccd/user1
ifconfig-push 172.26.0.100 255.255.254.0
push "sndbuf 524288"
push "rcvbuf 524288"

# 용도:
# - 특정 클라이언트에 고정 IP
# - 문제 클라이언트에 속도 제한
# - VIP 클라이언트에 더 큰 버퍼
```

---

### 7. 네트워크 인터페이스 최적화

```bash
# tun0 인터페이스 큐 길이 실시간 조정
ip link set dev tun0 txqueuelen 10000

# Ring buffer 크기 조정 (물리 인터페이스)
ethtool -G eth0 rx 4096 tx 4096

# Offload 기능 활성화
ethtool -K eth0 tso on gso on gro on
```

---

### 8. CPU Affinity (대규모 환경)

```bash
# OpenVPN 프로세스를 특정 CPU에 고정
# systemd 서비스 파일에 추가
CPUAffinity=0-3  # CPU 0,1,2,3 사용

# 또는 taskset 사용
taskset -c 0-3 openvpn --config server.conf
```

---

## 현재 설정 기준 권장 수정사항

### 귀하의 현재 설정 분석:
```conf
tcp-nodelay         # ✅ 유지
txqueuelen 5000     # ✅ 유지 (100~500명 적합)
tun-mtu-extra 32    # ✅ 유지
sndbuf 4194304      # ✅ 유지 (4MB, 100~500명 적합)
rcvbuf 4194304      # ✅ 유지
```

### 추가 권장 설정:

```conf
# ===== 필수 추가 =====
ifconfig-pool-persist /var/log/openvpn-ipp.txt  # IP 중복 방지
fast-io                                          # 논블로킹 I/O (proto udp 시)
compress stub-v2                                 # 압축 비활성화
push "compress stub-v2"

# ===== 암호화 최적화 =====
data-ciphers AES-128-GCM:AES-256-GCM
auth SHA256

# ===== 클라이언트 버퍼 푸시 =====
push "sndbuf 1048576"   # 클라이언트 송신 1MB
push "rcvbuf 1048576"   # 클라이언트 수신 1MB

# ===== Android 백그라운드 대응 =====
push "explicit-exit-notify 1"  # 빠른 재연결
ping-timer-rem

# ===== 모니터링 =====
status /var/log/openvpn-status.log 10
status-version 3
```

---

## 성능 측정 및 모니터링

### 실시간 모니터링 스크립트:

```bash
#!/bin/bash
# /usr/local/bin/openvpn-monitor.sh

echo "===== OpenVPN Performance Monitor ====="
echo ""

# 현재 연결 수
CLIENTS=$(grep -c "^172.26" /var/log/openvpn-status.log)
echo "Active Clients: $CLIENTS"

# tun0 트래픽
echo ""
echo "=== tun0 Interface ==="
ip -s link show tun0 | grep -A 1 "TX:"

# 큐 드롭
DROPS=$(ip -s link show tun0 | grep "TX:" -A 1 | tail -1 | awk '{print $4}')
echo "TX Dropped: $DROPS"

# CPU 사용률
echo ""
echo "=== CPU Usage ==="
top -b -n 1 | grep openvpn | head -5

# 메모리
echo ""
echo "=== Memory Usage ==="
ps aux | grep openvpn | awk '{sum+=$6} END {print "RSS: " sum/1024 " MB"}'

# 커널 버퍼
echo ""
echo "=== Kernel Buffers ==="
sysctl net.core.wmem_default net.core.wmem_max

# Send-Q 확인
echo ""
echo "=== TCP Send-Q Status ==="
ss -tn sport = :4443 | grep -v "0      0" | wc -l
echo "connections with queued data"
```

---

## 벤치마크 도구

```bash
# iperf3로 처리량 측정
# 서버
iperf3 -s

# 클라이언트 (VPN 통과)
iperf3 -c 172.26.0.1 -t 60 -P 10

# 결과 해석:
# 100Mbps 이상: 우수
# 50-100Mbps: 양호
# 50Mbps 미만: 최적화 필요
```

---

## 문제별 해결책

### 1. output saturation 계속 발생
```conf
# proto tcp → udp 변경 (근본 해결)
proto udp
sndbuf 8388608  # 버퍼 추가 상향
txqueuelen 10000
```

### 2. CPU 부하 높음
```conf
# 암호화 경량화
data-ciphers AES-128-GCM
compress stub-v2  # 압축 비활성화
verb 1           # 로그 최소화
```

### 3. 메모리 부족
```conf
# 버퍼 감소
sndbuf 1048576
rcvbuf 1048576
max-clients 축소
```

### 4. Android 백그라운드 문제
```conf
# 재연결 최적화
keepalive 5 30         # 더 자주 체크
push "explicit-exit-notify 1"
ping-timer-rem
```

---

## 스펙별 요약 테이블

| 설정 | 100명 미만 | 100~500명 | 500명 이상 |
|------|-----------|----------|-----------|
| **Proto** | tcp/udp | **udp** | **udp** |
| **txqueuelen** | 3000 | 5000 | 10000 |
| **sndbuf** | 2MB | 4MB | 8MB |
| **rcvbuf** | 2MB | 4MB | 8MB |
| **Cipher** | AES-256-GCM | AES-128-GCM | AES-128-GCM |
| **Compress** | lz4-v2 | stub-v2 | stub-v2 |
| **max-clients** | 150 | 600 | 1000+ |
| **Multi-instance** | No | No | **Yes** |
| **verb** | 3 | 3 | 1-3 |

---

## 적용 순서

1. **백업**
   ```bash
   cp server.conf server.conf.backup
   ```

2. **설정 변경**
   - ifconfig-pool-persist 추가
   - 스펙별 권장 설정 적용

3. **커널 파라미터 조정**
   ```bash
   vi /etc/sysctl.conf
   sysctl -p
   ```

4. **서비스 재시작**
   ```bash
   systemctl restart openvpn@server
   ```

5. **모니터링**
   ```bash
   watch -n 5 'ss -tn sport = :4443 | grep -v "0      0"'
   tail -f /var/log/openvpn.log | grep saturation
   ```

6. **성능 측정**
   - iperf3 벤치마크
   - 실제 사용자 피드백
   - output saturation 재발 여부

---

## 마지막 체크리스트

- [ ] ifconfig-pool-persist 설정 (IP 중복 방지)
- [ ] proto udp 전환 검토 (100명 이상)
- [ ] 커널 파라미터 튜닝
- [ ] 암호화 알고리즘 최적화
- [ ] 압축 비활성화 (stub-v2)
- [ ] 클라이언트 버퍼 푸시
- [ ] 모니터링 스크립트 설정
- [ ] 성능 벤치마크 실행
- [ ] 문제 클라이언트 대응 (ccd 활용)