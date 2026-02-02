# iOS Pribit Conect (OpenVPN) Split Tunnel DNS 문제 해결 기술 문서

## 문서 정보
- **작성일**: 2026-01-13
- **환경**: Pribit Connect OpenVPN Server (Ubuntu 24), Windows Server 2016 DNS, iOS Client
- **목적**: iOS에서 Pribit Connect (OpenVPN) Split Tunnel 사용 시 내부 DNS 서버를 정상적으로 사용하도록 설정

---

## 목차
1. [문제 개요](#1-문제-개요)
2. [환경 구성](#2-환경-구성)
3. [문제 분석 과정](#3-문제-분석-과정)
4. [근본 원인](#4-근본-원인)
5. [해결 방법](#5-해결-방법)
6. [설정 절차](#6-설정-절차)
7. [검증 및 테스트](#7-검증-및-테스트)
8. [트러블슈팅](#8-트러블슈팅)
9. [참고 자료](#9-참고-자료)

---

## 1. 문제 개요

### 1.1 증상
- OpenVPN server.conf에 `dhcp-option DNS 10.0.30.158` 설정 추가
- iOS 단말 VPN 접속 시 내부 DNS(10.0.30.158)를 사용하지 않음
- 외부 DNS(164.124.101.2, LG U+)를 사용하여 도메인 조회
- `docs.tech-packetgo.com` 조회 시:
  - **기대**: 내부 IP `10.0.30.159` 반환
  - **실제**: 외부 IP (AWS Cloud) 반환

### 1.2 목표
- Split Tunnel 환경에서 iOS가 내부 DNS 서버를 사용하도록 설정
- 내부 도메인(`tech-packetgo.com`)은 내부 IP로 해석
- 외부 도메인은 정상적인 DNS 조회 유지

---

## 2. 환경 구성

### 2.1 네트워크 구성도

```
[iOS Device]
    |
    | VPN Tunnel (10.21.0.2)
    |
[OpenVPN Gateway] (10.21.0.1)
    |
    | Internal Network
    |
[Windows DNS Server] (10.0.30.158)
    |
    +-- tech-packetgo.com zone
        +-- docs.tech-packetgo.com → 10.0.30.159
```

### 2.2 시스템 사양

#### OpenVPN 게이트웨이
- **OS**: Ubuntu 24.04 LTS
- **OpenVPN**: 2.6.x
- **IP**: 10.21.0.1 (VPN), 10.0.30.x (Internal)
- **역할**: VPN 서버, NAT 게이트웨이

#### DNS 서버
- **OS**: Windows Server 2016
- **DNS**: Microsoft DNS Server
- **IP**: 10.0.30.158
- **Zone**: tech-packetgo.com (Primary)

#### iOS 클라이언트
- **OS**: iOS 17.x
- **VPN App**: OpenVPN Connect
- **VPN IP**: 10.21.0.2
- **연결**: Wi-Fi / 셀룰러

### 2.3 초기 OpenVPN 설정

```bash
# /etc/openvpn/server.conf (초기)
port 1194
proto udp
dev tun
server 10.21.0.0 255.255.255.0

push "dhcp-option DNS 10.0.30.158"
push "block-outside-dns"
push "register-dns"
push "dhcp-option DOMAIN tech-packetgo.com"

push "route 10.0.30.0 255.255.255.0"
```

---

## 3. 문제 분석 과정

### 3.1 초기 진단

#### 테스트 방법
```bash
# OpenVPN 게이트웨이에서 패킷 캡처
tcpdump -i tun0 port 53 -nn -vv
```

#### 관찰 결과
```
# VPN 연결 직후 (검증 쿼리)
10.21.0.2 → 10.0.30.158:53 (UDP) PTR? lb._dns-sd._udp.some.company ✅
10.21.0.2 → 10.0.30.158:53 (UDP) SVCB? _dns.resolver.arpa ✅

# 실제 도메인 조회 시 (6초 후)
10.21.0.2 → 164.124.101.2:53 (TCP) A? docs.tech-packetgo.com ❌
```

**핵심 발견**:
1. iOS가 처음에는 VPN DNS(10.0.30.158)를 사용
2. 이후 외부 DNS(164.124.101.2)로 전환
3. 검증 쿼리는 UDP, 실제 쿼리는 TCP 사용

### 3.2 Full Tunnel 테스트

#### 설정
```bash
# server.conf에 추가
push "redirect-gateway def1 bypass-dhcp"
```

#### 결과
```
# tcpdump 출력
10.21.0.2 → 10.0.30.158:53 (TCP) A? docs.tech-packetgo.com ✅
10.0.30.158 → 10.21.0.2 응답: A 10.0.30.159 ✅

✅ Full Tunnel: 정상 작동
❌ Split Tunnel: 외부 DNS 사용
```

### 3.3 iOS nslookup 앱 테스트

#### Full Tunnel
```
Server: 10.0.30.158
Address: 10.0.30.158#53

docs.tech-packetgo.com → 10.0.30.159

Server 10.0.30.158 returned an authoritative response ✅
```

#### Split Tunnel
```
Server: 164.124.101.2
Address: 164.124.101.2#53

docs.tech-packetgo.com → 52.78.250.52 (AWS)

Server 164.124.101.2 returned non-authoritative response ❌
```

### 3.4 라우트 설정 테스트

#### 개별 IP 라우팅 시도
```bash
# server.conf
push "route 164.124.101.2 255.255.255.255"  # /32 호스트 라우트
push "route 203.248.252.2 255.255.255.255"
```
**결과**: iOS가 무시함 ❌

#### 서브넷 라우팅 시도
```bash
push "route 164.124.0.0 255.255.0.0"  # /16 서브넷
push "route 203.248.0.0 255.255.0.0"
```
**결과**: iOS가 무시함 ❌

#### /8 대역 라우팅 시도
```bash
push "route 128.0.0.0 255.0.0.0"  # 128.x.x.x 전체
```
**결과**: 패킷이 tun0에 보이지만 여전히 외부 DNS 사용 ❌

### 3.5 ipTIME AP DNS 설정 테스트

#### 설정
```
ipTIME 관리자 페이지
→ 네트워크 관리 → 내부 네트워크 설정
→ Primary DNS: 10.0.30.158
```

#### 결과
```
iOS (Wi-Fi) → VPN 연결 (Split Tunnel)
→ nslookup docs.tech-packetgo.com
→ Server: 10.0.30.158 ✅
→ Address: 10.0.30.159 ✅

✅ 성공!
```

---

## 4. 근본 원인

### 4.1 iOS DNS 선택 우선순위

iOS의 DNS 서버 선택 로직 (Split Tunnel 환경):

```
우선순위 1 (최고): 셀룰러 네트워크 DNS
              → ISP에서 자동 할당 (예: 164.124.101.2)

우선순위 2: Wi-Fi 네트워크 DNS
          → AP(공유기)의 DHCP에서 할당
          → ipTIME DNS 설정 시 10.0.30.158 ✅

우선순위 3 (최저): VPN DNS (dhcp-option DNS)
                 → OpenVPN push 설정
                 → Split Tunnel에서 무시되거나 낮은 우선순위
```

### 4.2 iOS의 DNS 검증 프로세스

```
┌─────────────────────────────────────────────┐
│ iOS VPN 연결 직후                            │
├─────────────────────────────────────────────┤
│ 1. VPN DNS(10.0.30.158) 검증 시도          │
│    - PTR? lb._dns-sd._udp.some.company     │
│    - SVCB? _dns.resolver.arpa              │
│    → UDP로 쿼리                              │
│                                             │
│ 2. 검증 결과 평가                           │
│    - SOA 레코드만 반환 (NXDOMAIN 아님)     │
│    - "레코드 없음" = 부정적 응답            │
│                                             │
│ 3. iOS 판단                                 │
│    "이 DNS는 제한적이다"                    │
│    "신뢰도 낮음, 우선순위 하락"             │
│                                             │
│ 4. 실제 도메인 조회 시 (약 6초 후)          │
│    - 더 신뢰할 만한 DNS 선택                │
│    - 셀룰러/Wi-Fi DNS로 전환               │
│    - TCP DNS 사용 시도                      │
└─────────────────────────────────────────────┘
```

### 4.3 라우팅 vs DNS 우선순위

**중요한 발견**:

```
iOS는 DNS 설정 우선순위가 라우팅보다 먼저 작동함

Split Tunnel 동작:
1. iOS가 DNS 서버 선택 (셀룰러/Wi-Fi DNS 우선)
2. 선택한 DNS 서버로 가는 라우팅 확인
3. 라우팅 없으면 → VPN 우회

Full Tunnel 동작:
1. iOS가 DNS 서버 선택 (여전히 셀룰러/Wi-Fi DNS)
2. 하지만 모든 IP가 VPN 라우트에 포함
3. 어떤 DNS를 선택해도 → VPN 통과 → iptables DNAT
```

### 4.4 iOS Network Extension의 제약

iOS의 `NEPacketTunnelProvider` (OpenVPN Connect가 사용):

```swift
// iOS 앱이 라우트를 시스템에 전달할 때
let ipv4Settings = NEIPv4Settings(...)
ipv4Settings.includedRoutes = [
    NEIPv4Route("10.0.30.0", "255.255.255.0"),    // ✅ 허용
    NEIPv4Route("164.124.101.2", "255.255.255.255") // ❌ 무시될 수 있음
]

// iOS가 특정 라우트를 거부하는 경우:
// 1. 보안 정책 (잘 알려진 Public DNS 보호)
// 2. 라우트 개수 제한
// 3. ISP DNS 범위 특별 보호
```

### 4.5 DNS over TCP vs UDP

```
검증 쿼리 (연결 직후):
- UDP 포트 53 사용
- VPN DNS로 전송 ✅

실제 쿼리 (검증 실패 후):
- TCP 포트 53 사용
- iOS가 "더 신뢰할 만한" 외부 DNS 선택
- 라우트 없으면 VPN 우회 ❌
```

---

## 5. 해결 방법

### 5.1 방법 비교표

| 방법 | Split Tunnel | Wi-Fi | 셀룰러 | 난이도 | 효과 |
|------|--------------|-------|---------|--------|------|
| ipTIME AP DNS 설정 | ✅ | ✅ | ❌ | ⭐ | 제한적 |
| Pseudo Full Tunnel | ❌ (사실상 Full) | ✅ | ✅ | ⭐⭐ | 확실함 |
| redirect-gateway | ❌ (Full Tunnel) | ✅ | ✅ | ⭐ | 확실함 |
| WireGuard 전환 | ✅ | ✅ | ✅ | ⭐⭐⭐⭐ | 완벽 |

### 5.2 방법 1: ipTIME AP DNS 설정 (Wi-Fi 환경)

#### 적용 대상
- 사무실/집 Wi-Fi만 사용하는 환경
- Split Tunnel 유지 필요
- 서버 설정 변경 최소화

#### 장점
- ✅ Split Tunnel 그대로 유지
- ✅ 서버 설정 변경 불필요
- ✅ 모든 기기에 자동 적용

#### 단점
- ❌ Wi-Fi에서만 작동
- ❌ 셀룰러에서는 여전히 외부 DNS 사용
- ❌ 모든 AP마다 설정 필요

#### 설정 방법

**ipTIME 관리자 페이지**:
```
1. http://192.168.0.1 접속
2. 고급 설정 → 네트워크 관리 → 내부 네트워크 설정
3. DNS 서버 설정:
   - Primary DNS: 10.0.30.158
   - Secondary DNS: 168.126.63.1 (백업용)
4. 저장 후 재부팅
```

**OpenVPN 서버** (변경 없음):
```bash
# /etc/openvpn/server.conf
push "dhcp-option DNS 10.0.30.158"
push "route 10.0.30.0 255.255.255.0"
```

### 5.3 방법 2: Pseudo Full Tunnel (권장)

#### 적용 대상
- 셀룰러, 외부 Wi-Fi에서도 사용
- 확실한 DNS 제어 필요
- 대역폭 증가 감수 가능

#### 장점
- ✅ 모든 네트워크 환경에서 작동
- ✅ Wi-Fi, 셀룰러 모두 지원
- ✅ DNS 확실히 제어

#### 단점
- ❌ 모든 트래픽이 VPN 경유 (Full Tunnel과 동일)
- ❌ 대역폭 사용량 증가
- ❌ 지연 시간 증가 가능

#### 설정 방법

**OpenVPN 서버**:
```bash
# /etc/openvpn/server.conf

# 기본 설정
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem

# VPN 네트워크
server 10.21.0.0 255.255.255.0
topology subnet
ifconfig-pool-persist ipp.txt
keepalive 10 120

# 보안
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun

# DNS 설정
push "dhcp-option DNS 10.0.30.158"
push "block-outside-dns"
push "register-dns"
push "dhcp-option DOMAIN tech-packetgo.com"

# 라우팅 - Pseudo Full Tunnel
push "route 10.0.30.0 255.255.255.0"
push "route 0.0.0.0 128.0.0.0"      # 0.x.x.x ~ 127.x.x.x
push "route 128.0.0.0 128.0.0.0"    # 128.x.x.x ~ 255.x.x.x

# DNS 리다이렉트
script-security 2
up /etc/openvpn/dns-redirect.sh

# 로깅
log /var/log/openvpn.log
status /var/log/openvpn-status.log
verb 3
```

**DNS 리다이렉트 스크립트**:
```bash
#!/bin/bash
# /etc/openvpn/dns-redirect.sh

VPN_INTERFACE="tun0"
VPN_SUBNET="10.21.0.0/24"
INTERNAL_DNS="10.0.30.158"

echo "=== DNS Redirection Setup ==="

# 기존 규칙 제거
iptables -t nat -F PREROUTING

# IP 포워딩
echo 1 > /proc/sys/net/ipv4/ip_forward

# DNS 리다이렉트 (UDP + TCP)
iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p udp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53
iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p tcp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53

# FORWARD 허용
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i $VPN_INTERFACE -j ACCEPT
iptables -A FORWARD -o $VPN_INTERFACE -j ACCEPT

# MASQUERADE
EXTERNAL_IF=$(ip route | grep default | awk '{print $5}')
iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o $EXTERNAL_IF -j MASQUERADE

echo "✓ DNS redirection configured"
logger "OpenVPN: DNS redirection active"
```

### 5.4 방법 3: redirect-gateway (간단)

#### 설정
```bash
# /etc/openvpn/server.conf
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 10.0.30.158"
push "route 10.0.30.0 255.255.255.0"

script-security 2
up /etc/openvpn/dns-redirect.sh
```

**효과**: 방법 2와 동일 (Full Tunnel)

### 5.5 방법 4: WireGuard 전환 (장기 솔루션)

#### 장점
- ✅ iOS에서 Split Tunnel + DNS가 안정적으로 작동
- ✅ 성능이 OpenVPN보다 우수
- ✅ 설정이 간단
- ✅ 배터리 효율 좋음

#### WireGuard 서버 설정
```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 10.21.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT

[Peer]
PublicKey = IOS_CLIENT_PUBLIC_KEY
AllowedIPs = 10.21.0.2/32
```

#### iOS 클라이언트 설정
```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.21.0.2/24
DNS = 10.0.30.158

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn-server-ip:51820
AllowedIPs = 10.0.30.0/24  # Split Tunnel
PersistentKeepalive = 25
```

---

## 6. 설정 절차

### 6.1 Windows DNS 서버 설정

#### 6.1.1 기본 영역 확인
```powershell
# 영역 확인
Get-DnsServerZone -Name "tech-packetgo.com"

# 기대 출력:
# ZoneType: Primary
# IsAutoCreated: False
```

#### 6.1.2 레코드 확인
```powershell
# A 레코드 확인
Get-DnsServerResourceRecord -ZoneName "tech-packetgo.com" -Name "docs"

# 기대 출력:
# docs.tech-packetgo.com → 10.0.30.159
```

#### 6.1.3 iOS 검증 영역 생성

iOS DNS 검증 쿼리를 처리하기 위한 영역:

```powershell
# resolver.arpa 영역 생성
Add-DnsServerPrimaryZone -Name "resolver.arpa" -ZoneFile "resolver.arpa.dns"

# 레코드 추가
Add-DnsServerResourceRecordA -Name "_dns" `
    -ZoneName "resolver.arpa" `
    -IPv4Address "10.0.30.158" `
    -TimeToLive 01:00:00

# 와일드카드 레코드 (모든 검증 쿼리 대응)
Add-DnsServerResourceRecordA -Name "*" `
    -ZoneName "resolver.arpa" `
    -IPv4Address "10.0.30.158" `
    -TimeToLive 01:00:00

# some.company 영역 생성
Add-DnsServerPrimaryZone -Name "some.company" -ZoneFile "some.company.dns"

Add-DnsServerResourceRecordA -Name "lb._dns-sd._udp" `
    -ZoneName "some.company" `
    -IPv4Address "10.0.30.158" `
    -TimeToLive 01:00:00

Add-DnsServerResourceRecordA -Name "*" `
    -ZoneName "some.company" `
    -IPv4Address "10.0.30.158" `
    -TimeToLive 01:00:00
```

#### 6.1.4 DNS 로깅 활성화
```powershell
# 디버그 로깅 활성화
Set-DnsServerDiagnostics -Queries $true -QueryLog $true

# 로그 확인
Get-Content "C:\Windows\System32\dns\dns.log" -Wait -Tail 20
```

#### 6.1.5 방화벽 확인
```powershell
# TCP 53 방화벽 규칙 추가
New-NetFirewallRule -DisplayName "Allow DNS TCP from VPN" `
    -Direction Inbound -Protocol TCP -LocalPort 53 `
    -RemoteAddress 10.21.0.0/24 -Action Allow -Enabled True

# DNS 리스닝 확인
netstat -an | findstr ":53"

# 기대 출력:
# TCP    10.0.30.158:53    LISTENING
# UDP    10.0.30.158:53    *:*
```

### 6.2 OpenVPN 게이트웨이 설정

#### 6.2.1 server.conf 구성 (Pseudo Full Tunnel)

```bash
# /etc/openvpn/server.conf
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem

server 10.21.0.0 255.255.255.0
topology subnet
ifconfig-pool-persist /var/log/openvpn/ipp.txt
keepalive 10 120

cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun

# DNS 설정
push "dhcp-option DNS 10.0.30.158"
push "block-outside-dns"
push "register-dns"
push "dhcp-option DOMAIN tech-packetgo.com"

# 라우팅
push "route 10.0.30.0 255.255.255.0"
push "route 0.0.0.0 128.0.0.0"
push "route 128.0.0.0 128.0.0.0"

# 스크립트
script-security 2
up /etc/openvpn/dns-redirect.sh

# 로깅
log /var/log/openvpn.log
status /var/log/openvpn-status.log
verb 3
```

#### 6.2.2 DNS 리다이렉트 스크립트

```bash
cat > /etc/openvpn/dns-redirect.sh << 'EOFSCRIPT'
#!/bin/bash

VPN_INTERFACE="tun0"
VPN_SUBNET="10.21.0.0/24"
INTERNAL_DNS="10.0.30.158"

echo "=== DNS Redirection Setup ==="
echo "VPN Interface: $VPN_INTERFACE"
echo "VPN Subnet: $VPN_SUBNET"
echo "Internal DNS: $INTERNAL_DNS"

# 기존 규칙 제거 (재시작 시)
iptables -t nat -F PREROUTING 2>/dev/null

# IP 포워딩 활성화
echo 1 > /proc/sys/net/ipv4/ip_forward

# DNS 리다이렉트 (UDP + TCP)
echo "Adding DNS redirection rules..."
iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p udp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53
iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p tcp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53

# FORWARD 체인 허용
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i $VPN_INTERFACE -j ACCEPT
iptables -A FORWARD -o $VPN_INTERFACE -j ACCEPT

# MASQUERADE
EXTERNAL_IF=$(ip route | grep default | awk '{print $5}')
if [ -n "$EXTERNAL_IF" ]; then
    iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o $EXTERNAL_IF -j MASQUERADE
    echo "  ✓ MASQUERADE on $EXTERNAL_IF"
fi

echo "=== Setup Complete ==="
echo "Applied NAT rules:"
iptables -t nat -L PREROUTING -n -v | grep "dpt:53"

logger "OpenVPN: DNS redirection configured for $VPN_SUBNET -> $INTERNAL_DNS"
EOFSCRIPT

chmod +x /etc/openvpn/dns-redirect.sh
```

#### 6.2.3 OpenVPN 서비스 재시작

```bash
# 설정 테스트
openvpn --config /etc/openvpn/server.conf --verb 4 --test-crypto

# 재시작
systemctl restart openvpn@server

# 상태 확인
systemctl status openvpn@server

# 로그 확인
tail -50 /var/log/openvpn.log
```

#### 6.2.4 iptables 규칙 확인

```bash
# NAT 테이블 확인
iptables -t nat -L PREROUTING -n -v

# 기대 출력:
# Chain PREROUTING (policy ACCEPT)
# pkts bytes target     prot opt in     out     source      destination
#    0     0 DNAT       udp  --  tun0   *       0.0.0.0/0   0.0.0.0/0   udp dpt:53 to:10.0.30.158:53
#    0     0 DNAT       tcp  --  tun0   *       0.0.0.0/0   0.0.0.0/0   tcp dpt:53 to:10.0.30.158:53

# FORWARD 테이블 확인
iptables -L FORWARD -n -v | head -20
```

### 6.3 iOS 클라이언트 설정

#### 6.3.1 OpenVPN Connect 앱 설치
```
App Store → "OpenVPN Connect" 검색 및 설치
```

#### 6.3.2 프로파일 가져오기
```
1. .ovpn 파일을 iOS로 전송 (이메일, AirDrop 등)
2. OpenVPN Connect 앱에서 Import
3. 연결 정보 입력 (필요 시)
```

#### 6.3.3 중요 설정 확인

**iCloud Private Relay 비활성화**:
```
설정 > [사용자 이름] > iCloud > Private Relay
→ 비활성화 (필수!)
```

**Safari 설정**:
```
설정 > Safari
→ IP 주소 숨기기 → 추적자 및 웹사이트 끄기
```

#### 6.3.4 수동 DNS 설정 (옵션)

OpenVPN Connect 앱에서:
```
1. 프로파일 편집
2. Connection → DNS Settings
3. Automatic → Manual 변경
4. Primary DNS: 10.0.30.158
5. Search Domains: tech-packetgo.com
6. 저장
```

---

## 7. 검증 및 테스트

### 7.1 테스트 환경별 체크리스트

#### 시나리오 1: 내부 Wi-Fi (ipTIME DNS 설정)

**사전 조건**:
- ipTIME DNS = 10.0.30.158
- OpenVPN Split Tunnel

**테스트**:
```
iOS:
1. Wi-Fi 연결 (ipTIME)
2. VPN 연결
3. nslookup docs.tech-packetgo.com

기대 결과:
Server: 10.0.30.158
Address: 10.0.30.159
```

#### 시나리오 2: 셀룰러 네트워크

**사전 조건**:
- OpenVPN Pseudo Full Tunnel

**테스트**:
```
iOS:
1. Wi-Fi 끄기 (셀룰러만)
2. VPN 연결
3. nslookup docs.tech-packetgo.com

기대 결과:
Server: 10.0.30.158
Address: 10.0.30.159
```

#### 시나리오 3: 외부 Wi-Fi (카페, 공항 등)

**사전 조건**:
- OpenVPN Pseudo Full Tunnel

**테스트**:
```
iOS:
1. 외부 Wi-Fi 연결
2. VPN 연결
3. nslookup docs.tech-packetgo.com

기대 결과:
Server: 10.0.30.158
Address: 10.0.30.159
```

### 7.2 게이트웨이 모니터링

#### 실시간 DNS 트래픽 확인

```bash
# 터미널 1: DNS 패킷 캡처
tcpdump -i tun0 'host 10.21.0.2 and port 53' -nn -vv

# 터미널 2: iptables NAT 카운터
watch -n 1 'iptables -t nat -L PREROUTING -n -v | grep dpt:53'

# 터미널 3: OpenVPN 로그
tail -f /var/log/openvpn.log
```

#### 통합 모니터링 스크립트

```bash
#!/bin/bash
# /root/monitor-ios-dns.sh

echo "=== iOS DNS 모니터링 ==="
echo "iOS에서 VPN 연결 후 docs.tech-packetgo.com 조회하세요"
echo "Ctrl+C로 중지"
echo ""

timeout 30 tcpdump -i tun0 'host 10.21.0.2 and port 53' -nn -l | \
while IFS= read -r line; do
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] $line"
done

echo ""
echo "=== iptables NAT 통계 ==="
iptables -t nat -L PREROUTING -n -v | grep dpt:53
```

### 7.3 Windows DNS 로그 확인

```powershell
# 실시간 로그 모니터링
Get-Content "C:\Windows\System32\dns\dns.log" -Wait -Tail 20 | 
    Where-Object {$_ -match "10.21.0.2"}

# 특정 도메인 쿼리 검색
Get-Content "C:\Windows\System32\dns\dns.log" | 
    Select-String "tech-packetgo.com" | 
    Select-Object -Last 10
```

### 7.4 성공 기준

#### ✅ 정상 작동 확인 지표

**1. tcpdump 출력**:
```
10.21.0.2.xxxxx > 10.0.30.158.53: A? docs.tech-packetgo.com
10.0.30.158.53 > 10.21.0.2.xxxxx: A 10.0.30.159
```

**2. iptables 카운터 증가**:
```
Chain PREROUTING (policy ACCEPT 15 packets, 1234 bytes)
pkts bytes target     prot opt in     out     source      destination
  15  1234 DNAT       udp  --  tun0   *       0.0.0.0/0   0.0.0.0/0   udp dpt:53 to:10.0.30.158:53
```

**3. Windows DNS 로그**:
```
10.21.0.2 - Query, docs.tech-packetgo.com, A
10.21.0.2 - Response, 10.0.30.159
```

**4. iOS nslookup 결과**:
```
Server: 10.0.30.158
Address: 10.0.30.158#53

docs.tech-packetgo.com → 10.0.30.159

Server 10.0.30.158 returned an authoritative response
```

---

## 8. 트러블슈팅

### 8.1 증상별 해결 방법

#### 문제 1: iOS가 여전히 외부 DNS 사용

**증상**:
```
iOS nslookup 결과:
Server: 164.124.101.2
Address: 외부 IP
```

**원인 진단**:
```bash
# 1. OpenVPN PUSH 확인
tail -100 /var/log/openvpn.log | grep PUSH_REPLY

# 기대 출력에 포함되어야 함:
# route 0.0.0.0 128.0.0.0
# route 128.0.0.0 128.0.0.0

# 2. iptables 규칙 확인
iptables -t nat -L PREROUTING -n -v | grep dpt:53

# 3. iOS Private Relay 확인
# 설정 > Apple ID > iCloud > Private Relay
# → 반드시 꺼져 있어야 함!
```

**해결 방법**:
```bash
# server.conf 확인 및 수정
grep "route 0.0.0.0" /etc/openvpn/server.conf

# 없으면 추가
echo 'push "route 0.0.0.0 128.0.0.0"' >> /etc/openvpn/server.conf
echo 'push "route 128.0.0.0 128.0.0.0"' >> /etc/openvpn/server.conf

# 재시작
systemctl restart openvpn@server
```

#### 문제 2: VPN 연결 후 인터넷 안 됨

**증상**:
- VPN 연결 성공
- 내부 DNS는 작동
- 외부 웹사이트 접속 불가

**원인**: MASQUERADE 설정 누락

**해결 방법**:
```bash
# 외부 인터페이스 확인
ip route | grep default

# MASQUERADE 규칙 추가
EXTERNAL_IF=eth0  # 실제 인터페이스명으로 변경
iptables -t nat -A POSTROUTING -s 10.21.0.0/24 -o $EXTERNAL_IF -j MASQUERADE

# 영구 적용
apt-get install iptables-persistent
iptables-save > /etc/iptables/rules.v4
```

#### 문제 3: DNS 쿼리가 tun0에 안 보임

**증상**:
```bash
tcpdump -i tun0 port 53
# 패킷 없음
```

**원인 진단**:
```bash
# iOS가 DNS를 VPN으로 안 보냄
# 외부 인터페이스 확인
tcpdump -i eth0 'src 10.21.0.2 and port 53' -nn -c 5
```

**해결 방법**:
```bash
# Full Tunnel로 전환
# server.conf
push "redirect-gateway def1 bypass-dhcp"

# 또는 Wi-Fi 환경에서만 사용 (ipTIME DNS 설정)
```

#### 문제 4: Windows DNS 서버 응답 안 함

**증상**:
- tcpdump에는 패킷 보임
- Windows DNS 로그에 없음

**원인 진단**:
```powershell
# Windows에서
# 1. DNS 서비스 확인
Get-Service DNS

# 2. 방화벽 확인
Get-NetFirewallRule -DisplayName "*DNS*"

# 3. 리스닝 포트 확인
netstat -an | findstr ":53"
```

**해결 방법**:
```powershell
# DNS 서비스 재시작
Restart-Service DNS

# 방화벽 규칙 추가
New-NetFirewallRule -DisplayName "Allow DNS from VPN" `
    -Direction Inbound -Protocol UDP -LocalPort 53 `
    -RemoteAddress 10.21.0.0/24 -Action Allow

New-NetFirewallRule -DisplayName "Allow DNS TCP from VPN" `
    -Direction Inbound -Protocol TCP -LocalPort 53 `
    -RemoteAddress 10.21.0.0/24 -Action Allow
```

#### 문제 5: 검증 쿼리만 VPN DNS, 실제는 외부 DNS

**증상**:
```
연결 직후: 10.0.30.158 사용 ✅
6초 후: 164.124.101.2로 전환 ❌
```

**원인**: iOS DNS 검증 실패 (SOA만 반환)

**해결 방법**:
```powershell
# Windows DNS 서버에서
# resolver.arpa와 some.company에 실제 레코드 추가

Add-DnsServerResourceRecordA -Name "_dns" `
    -ZoneName "resolver.arpa" `
    -IPv4Address "10.0.30.158"

Add-DnsServerResourceRecordA -Name "*" `
    -ZoneName "resolver.arpa" `
    -IPv4Address "10.0.30.158"

Add-DnsServerResourceRecordA -Name "*" `
    -ZoneName "some.company" `
    -IPv4Address "10.0.30.158"
```

### 8.2 진단 도구

#### 통합 진단 스크립트 (Linux)

```bash
#!/bin/bash
# /root/diagnose-ios-dns.sh

echo "=== iOS OpenVPN DNS 진단 ==="
echo ""

echo "1. OpenVPN 서비스 상태:"
systemctl status openvpn@server --no-pager | head -3
echo ""

echo "2. server.conf 라우트 설정:"
grep "^push \"route" /etc/openvpn/server.conf
echo ""

echo "3. iptables NAT 규칙:"
iptables -t nat -L PREROUTING -n -v | grep dpt:53
echo ""

echo "4. IP 포워딩 상태:"
cat /proc/sys/net/ipv4/ip_forward
echo ""

echo "5. 최근 PUSH_REPLY:"
tail -50 /var/log/openvpn.log | grep PUSH_REPLY | tail -1
echo ""

echo "6. 연결된 클라이언트:"
cat /var/log/openvpn-status.log | grep "10.21.0"
echo ""

echo "7. 외부 인터페이스 및 MASQUERADE:"
ip route | grep default
iptables -t nat -L POSTROUTING -n -v | grep MASQUERADE
echo ""

echo "=== 진단 완료 ==="
echo "다음 단계:"
echo "1. iOS VPN 재연결"
echo "2. tcpdump -i tun0 'port 53' -nn"
echo "3. iOS에서 nslookup docs.tech-packetgo.com"
```

#### 통합 진단 스크립트 (Windows)

```powershell
# diagnose-dns-server.ps1

Write-Host "=== Windows DNS 서버 진단 ===" -ForegroundColor Green
Write-Host ""

Write-Host "1. DNS 서비스 상태:" -ForegroundColor Yellow
Get-Service DNS | Select-Object Status, StartType
Write-Host ""

Write-Host "2. tech-packetgo.com 영역:" -ForegroundColor Yellow
Get-DnsServerZone -Name "tech-packetgo.com" | 
    Select-Object ZoneName, ZoneType, IsDsIntegrated
Write-Host ""

Write-Host "3. docs 레코드:" -ForegroundColor Yellow
Get-DnsServerResourceRecord -ZoneName "tech-packetgo.com" -Name "docs" | 
    Select-Object HostName, RecordType, @{N='IP';E={$_.RecordData.IPv4Address}}
Write-Host ""

Write-Host "4. 검증 영역 (resolver.arpa, some.company):" -ForegroundColor Yellow
Get-DnsServerZone | Where-Object {$_.ZoneName -in @("resolver.arpa","some.company")} | 
    Select-Object ZoneName, ZoneType
Write-Host ""

Write-Host "5. 방화벽 규칙:" -ForegroundColor Yellow
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*DNS*"} | 
    Select-Object DisplayName, Enabled, Direction | Format-Table -AutoSize
Write-Host ""

Write-Host "6. 리스닝 포트:" -ForegroundColor Yellow
netstat -an | findstr ":53" | Select-Object -First 5
Write-Host ""

Write-Host "7. 최근 DNS 쿼리 (VPN 클라이언트):" -ForegroundColor Yellow
if (Test-Path "C:\Windows\System32\dns\dns.log") {
    Get-Content "C:\Windows\System32\dns\dns.log" | 
        Select-String "10.21.0" | 
        Select-Object -Last 5
} else {
    Write-Host "   DNS 로깅이 비활성화되어 있습니다." -ForegroundColor Yellow
    Write-Host "   활성화: Set-DnsServerDiagnostics -Queries `$true" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== 진단 완료 ===" -ForegroundColor Green
```

### 8.3 성능 최적화

#### 압축 활성화

```bash
# server.conf
comp-lzo
push "comp-lzo"
```

#### MTU 최적화

```bash
# server.conf
tun-mtu 1400
mssfix 1360
fragment 1300
```

#### DNS 캐시 최적화

```powershell
# Windows DNS 서버
Set-DnsServerCache -MaxTTL 01:00:00 -MaxNegativeTTL 00:05:00
```

---

## 9. 참고 자료

### 9.1 관련 기술 문서

#### OpenVPN
- [OpenVPN 공식 문서](https://openvpn.net/community-resources/)
- [OpenVPN HOWTO](https://openvpn.net/community-resources/how-to/)
- [OpenVPN Route 설정](https://community.openvpn.net/openvpn/wiki/RoutedLans)

#### iOS Network Extension
- [Apple Network Extension Framework](https://developer.apple.com/documentation/networkextension)
- [NEPacketTunnelProvider](https://developer.apple.com/documentation/networkextension/nepackettunnelprovider)
- [iOS VPN Configuration](https://developer.apple.com/documentation/networkextension/personal_vpn)

#### DNS
- [RFC 1035: DNS Specification](https://www.rfc-editor.org/rfc/rfc1035)
- [DNS over TCP](https://www.rfc-editor.org/rfc/rfc7766)
- [Windows DNS Server Documentation](https://docs.microsoft.com/en-us/windows-server/networking/dns/)

### 9.2 주요 명령어 요약

#### Linux (OpenVPN 게이트웨이)

```bash
# OpenVPN 관리
systemctl status openvpn@server
systemctl restart openvpn@server
systemctl enable openvpn@server

# 로그 확인
tail -f /var/log/openvpn.log
journalctl -u openvpn@server -f

# 패킷 캡처
tcpdump -i tun0 port 53 -nn -vv
tcpdump -i tun0 host 10.21.0.2 -nn

# iptables 확인
iptables -t nat -L PREROUTING -n -v
iptables -L FORWARD -n -v
iptables-save

# IP 포워딩
sysctl net.ipv4.ip_forward
echo 1 > /proc/sys/net/ipv4/ip_forward

# 설정 파일
/etc/openvpn/server.conf
/etc/openvpn/dns-redirect.sh
```

#### Windows (DNS 서버)

```powershell
# DNS 서비스
Get-Service DNS
Restart-Service DNS

# 영역 관리
Get-DnsServerZone
Get-DnsServerResourceRecord -ZoneName "tech-packetgo.com"
Add-DnsServerResourceRecordA -Name "docs" -ZoneName "tech-packetgo.com" -IPv4Address "10.0.30.159"

# 로깅
Set-DnsServerDiagnostics -Queries $true -QueryLog $true
Get-Content "C:\Windows\System32\dns\dns.log" -Wait -Tail 20

# 방화벽
Get-NetFirewallRule -DisplayName "*DNS*"
New-NetFirewallRule -DisplayName "Allow DNS from VPN" -Direction Inbound -Protocol UDP -LocalPort 53 -RemoteAddress 10.21.0.0/24 -Action Allow

# 테스트
nslookup docs.tech-packetgo.com 10.0.30.158
Resolve-DnsName -Name docs.tech-packetgo.com -Server 10.0.30.158
```

#### iOS 설정 확인

```
# 설정 앱
설정 > 일반 > VPN 및 기기 관리
설정 > [사용자] > iCloud > Private Relay → 끄기
설정 > Safari > IP 주소 숨기기 → 끄기

# nslookup (앱 설치 필요)
nslookup docs.tech-packetgo.com
```

### 9.3 자주 발생하는 오류

| 오류 | 원인 | 해결 |
|------|------|------|
| "Connection timeout" | 방화벽 차단 | UDP 1194 허용 |
| "TLS handshake failed" | 인증서 문제 | 인증서 재생성 |
| "Cannot resolve hostname" | DNS 미작동 | Windows DNS 서비스 확인 |
| "Route already exists" | 라우트 충돌 | 기존 라우트 삭제 |
| "Permission denied" | 권한 부족 | sudo 사용 또는 관리자 권한 |

### 9.4 보안 고려사항

#### 1. 인증서 관리
```bash
# 인증서 만료 확인
openssl x509 -in /etc/openvpn/server.crt -noout -dates

# 인증서 갱신 (Easy-RSA 사용)
cd /etc/openvpn/easy-rsa
./easyrsa renew server
```

#### 2. 강력한 암호화
```bash
# server.conf
cipher AES-256-GCM
auth SHA512
tls-version-min 1.2
```

#### 3. 방화벽 설정
```bash
# OpenVPN 포트만 허용
ufw allow 1194/udp
ufw enable

# SSH 접근 제한
ufw allow from 192.168.0.0/24 to any port 22
```

#### 4. 로그 모니터링
```bash
# 실시간 로그 모니터링
tail -f /var/log/openvpn.log | grep -E "VERIFY|AUTH|ERROR"

# 로그 로테이션 설정
# /etc/logrotate.d/openvpn
/var/log/openvpn.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

### 9.5 성능 튜닝

#### OpenVPN 성능 최적화
```bash
# server.conf
sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"

# 압축 (CPU 사용 주의)
comp-lzo adaptive

# 병렬 처리
txqueuelen 1000
```

#### 시스템 최적화
```bash
# sysctl 설정
cat >> /etc/sysctl.conf << EOF
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.ip_forward = 1
EOF

sysctl -p
```

---

## 10. 결론

### 10.1 핵심 발견

1. **iOS는 Split Tunnel에서 VPN DNS 설정을 무시하거나 낮은 우선순위로 처리**
   - Wi-Fi/셀룰러 DNS가 최우선
   - VPN의 `dhcp-option DNS`는 참고사항으로만 사용

2. **iOS는 VPN 라우트 설정을 선택적으로 무시**
   - `/32` 호스트 라우트: 무시됨
   - `/16`, `/8` 서브넷: 무시될 수 있음
   - `0.0.0.0/1` + `128.0.0.0/1`: 인식됨 (Full Tunnel 패턴)

3. **DNS 검증 프로세스의 중요성**
   - iOS는 VPN DNS 서버를 검증 (PTR, SVCB 쿼리)
   - 부정적 응답(SOA만) 수신 시 신뢰도 하락
   - 이후 외부 DNS로 전환

4. **네트워크 인터페이스 수준의 DNS 설정이 가장 효과적**
   - AP(ipTIME) DNS 설정 → Wi-Fi DNS가 내부 DNS
   - iOS가 "기본 DNS"로 인식
   - VPN 설정과 무관하게 작동

### 10.2 권장 솔루션

#### 환경별 최적 솔루션

| 사용 환경 | 권장 방법 | Split Tunnel | 복잡도 |
|-----------|-----------|--------------|--------|
| 사무실 Wi-Fi만 | ipTIME DNS 설정 | ✅ | ⭐ |
| 외부 + 셀룰러 | Pseudo Full Tunnel | ❌ | ⭐⭐ |
| 장기 운영 | WireGuard 전환 | ✅ | ⭐⭐⭐⭐ |

#### 단계별 접근

**1단계**: ipTIME AP DNS 설정
- 가장 간단하고 효과적
- Wi-Fi 환경에서만 작동

**2단계**: Pseudo Full Tunnel 적용
- 모든 환경에서 작동
- 대역폭 증가 감수

**3단계**: WireGuard 전환 검토
- iOS에서 Split Tunnel + DNS 안정적
- 성능 우수

### 10.3 남은 과제

1. **DoH/DoT 차단**
   - iOS가 DNS over HTTPS 사용 시 포트 53 우회
   - 443 포트로 암호화된 DNS 쿼리
   - 현재 Full Tunnel로 우회 가능

2. **iCloud Private Relay**
   - 활성화 시 모든 DNS/HTTP 트래픽 Apple 경유
   - 사용자 교육 필요 (반드시 끄기)

3. **Android 호환성**
   - Android는 `dhcp-option DNS` 잘 따름
   - iOS만의 특수한 문제

### 10.4 교훈

1. **iOS VPN은 특별하다**
   - Android/Linux와 다른 DNS 처리 방식
   - Network Extension Framework의 제약
   - Apple 생태계의 보안 정책

2. **Full Tunnel이 가장 확실하다**
   - Split Tunnel은 iOS에서 제한적
   - 확실한 제어가 필요하면 Full Tunnel

3. **테스트가 중요하다**
   - 다양한 네트워크 환경 테스트 필수
   - Wi-Fi, 셀룰러 각각 검증
   - 실제 사용 시나리오 재현

4. **문서화와 모니터링**
   - 상세한 로그 수집
   - 패킷 캡처 분석
   - 문제 재현 절차 기록

---

## 부록 A: 전체 설정 파일 예제

### A.1 OpenVPN server.conf (Pseudo Full Tunnel)

```bash
# /etc/openvpn/server.conf
# iOS OpenVPN DNS Solution - Pseudo Full Tunnel

# 기본 설정
port 1194
proto udp
dev tun

# 인증서
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem

# 네트워크
server 10.21.0.0 255.255.255.0
topology subnet
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# 연결 유지
keepalive 10 120
persist-key
persist-tun

# 보안
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup

# DNS 설정
push "dhcp-option DNS 10.0.30.158"
push "block-outside-dns"
push "register-dns"
push "dhcp-option DOMAIN tech-packetgo.com"

# 라우팅 - Pseudo Full Tunnel
push "route 10.0.30.0 255.255.255.0"
push "route 0.0.0.0 128.0.0.0"
push "route 128.0.0.0 128.0.0.0"

# 압축 (선택)
comp-lzo adaptive

# MTU 최적화
tun-mtu 1400
mssfix 1360

# 스크립트
script-security 2
up /etc/openvpn/dns-redirect.sh

# 로깅
log /var/log/openvpn.log
status /var/log/openvpn-status.log
verb 3
```

### A.2 DNS 리다이렉트 스크립트

```bash
#!/bin/bash
# /etc/openvpn/dns-redirect.sh

VPN_INTERFACE="tun0"
VPN_SUBNET="10.21.0.0/24"
INTERNAL_DNS="10.0.30.158"

echo "=== OpenVPN DNS Redirection Setup ==="
echo "Date: $(date)"
echo "VPN Interface: $VPN_INTERFACE"
echo "VPN Subnet: $VPN_SUBNET"
echo "Internal DNS: $INTERNAL_DNS"
echo ""

# 기존 규칙 제거
echo "Flushing existing NAT rules..."
iptables -t nat -F PREROUTING 2>/dev/null || true

# IP 포워딩 활성화
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# DNS 리다이렉트 (UDP + TCP)
echo "Adding DNS redirection rules..."
iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p udp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53
echo "  ✓ UDP DNS redirect: $VPN_INTERFACE:53 → $INTERNAL_DNS:53"

iptables -t nat -A PREROUTING -i $VPN_INTERFACE -p tcp --dport 53 \
    -j DNAT --to-destination $INTERNAL_DNS:53
echo "  ✓ TCP DNS redirect: $VPN_INTERFACE:53 → $INTERNAL_DNS:53"

# FORWARD 체인 허용
echo "Configuring FORWARD chain..."
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -s $VPN_SUBNET -d $INTERNAL_DNS -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i $VPN_INTERFACE -j ACCEPT
iptables -A FORWARD -o $VPN_INTERFACE -j ACCEPT
echo "  ✓ FORWARD rules configured"

# MASQUERADE
EXTERNAL_IF=$(ip route | grep default | awk '{print $5}')
if [ -n "$EXTERNAL_IF" ]; then
    iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o $EXTERNAL_IF -j MASQUERADE
    echo "  ✓ MASQUERADE configured on $EXTERNAL_IF"
else
    echo "  ⚠ Warning: Could not detect external interface"
fi

# 규칙 확인
echo ""
echo "=== Applied NAT Rules (PREROUTING) ==="
iptables -t nat -L PREROUTING -n -v | grep "dpt:53"

echo ""
echo "=== Applied FORWARD Rules ==="
iptables -L FORWARD -n -v | grep -E "10.0.30.158|$VPN_INTERFACE" | head -5

# 로그 기록
logger "OpenVPN: DNS redirection configured - $VPN_SUBNET -> $INTERNAL_DNS"

echo ""
echo "=== Setup Complete ==="
echo "DNS redirection is now active for iOS devices"
```

### A.3 Windows DNS 서버 초기화 스크립트

```powershell
# Setup-iOS-DNS-Zones.ps1
# iOS OpenVPN DNS 검증 영역 생성 스크립트

param(
    [string]$InternalDNS = "10.0.30.158",
    [string]$InternalIP = "10.0.30.159",
    [string]$PrimaryZone = "tech-packetgo.com"
)

Write-Host "=== iOS DNS 영역 초기화 스크립트 ===" -ForegroundColor Green
Write-Host "Internal DNS: $InternalDNS" -ForegroundColor Cyan
Write-Host "Internal IP: $InternalIP" -ForegroundColor Cyan
Write-Host "Primary Zone: $PrimaryZone" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "관리자 권한으로 실행해주세요!"
    Exit 1
}

# 1. resolver.arpa 영역
Write-Host "1. resolver.arpa 영역 생성..." -ForegroundColor Yellow
try {
    $zone = Get-DnsServerZone -Name "resolver.arpa" -ErrorAction Stop
    Write-Host "   ✓ 영역이 이미 존재합니다." -ForegroundColor Cyan
} catch {
    Add-DnsServerPrimaryZone -Name "resolver.arpa" -ZoneFile "resolver.arpa.dns" -PassThru | Out-Null
    Write-Host "   ✓ 영역 생성 완료" -ForegroundColor Green
}

# _dns 레코드
try {
    $record = Get-DnsServerResourceRecord -ZoneName "resolver.arpa" -Name "_dns" -RRType A -ErrorAction Stop
    Write-Host "   ✓ _dns 레코드 존재: $($record.RecordData.IPv4Address)" -ForegroundColor Cyan
} catch {
    Add-DnsServerResourceRecordA -Name "_dns" -ZoneName "resolver.arpa" `
        -IPv4Address $InternalDNS -TimeToLive 01:00:00 -PassThru | Out-Null
    Write-Host "   ✓ _dns 레코드 추가: $InternalDNS" -ForegroundColor Green
}

# 와일드카드 레코드
try {
    $record = Get-DnsServerResourceRecord -ZoneName "resolver.arpa" -Name "*" -RRType A -ErrorAction Stop
    Write-Host "   ✓ 와일드카드 레코드 존재" -ForegroundColor Cyan
} catch {
    Add-DnsServerResourceRecordA -Name "*" -ZoneName "resolver.arpa" `
        -IPv4Address $InternalDNS -TimeToLive 01:00:00 -PassThru | Out-Null
    Write-Host "   ✓ 와일드카드 레코드 추가" -ForegroundColor Green
}

# 2. some.company 영역
Write-Host "`n2. some.company 영역 생성..." -ForegroundColor Yellow
try {
    $zone = Get-DnsServerZone -Name "some.company" -ErrorAction Stop
    Write-Host "   ✓ 영역이 이미 존재합니다." -ForegroundColor Cyan
} catch {
    Add-DnsServerPrimaryZone -Name "some.company" -ZoneFile "some.company.dns" -PassThru | Out-Null
    Write-Host "   ✓ 영역 생성 완료" -ForegroundColor Green
}

# 와일드카드 레코드
try {
    $record = Get-DnsServerResourceRecord -ZoneName "some.company" -Name "*" -RRType A -ErrorAction Stop
    Write-Host "   ✓ 와일드카드 레코드 존재" -ForegroundColor Cyan
} catch {
    Add-DnsServerResourceRecordA -Name "*" -ZoneName "some.company" `
        -IPv4Address $InternalDNS -TimeToLive 01:00:00 -PassThru | Out-Null
    Write-Host "   ✓ 와일드카드 레코드 추가" -ForegroundColor Green
}

# 3. 주 영역 확인
Write-Host "`n3. $PrimaryZone 영역 확인..." -ForegroundColor Yellow
try {
    $zone = Get-DnsServerZone -Name $PrimaryZone -ErrorAction Stop
    Write-Host "   ✓ 영역 존재: $($zone.ZoneType)" -ForegroundColor Green
    
    # docs 레코드 확인
    try {
        $record = Get-DnsServerResourceRecord -ZoneName $PrimaryZone -Name "docs" -RRType A -ErrorAction Stop
        Write-Host "   ✓ docs 레코드 존재: $($record.RecordData.IPv4Address)" -ForegroundColor Cyan
    } catch {
        Write-Host "   ! docs 레코드가 없습니다." -ForegroundColor Yellow
        Write-Host "     추가 명령: Add-DnsServerResourceRecordA -Name 'docs' -ZoneName '$PrimaryZone' -IPv4Address '$InternalIP'" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ $PrimaryZone 영역이 없습니다." -ForegroundColor Red
    Write-Host "     생성 명령: Add-DnsServerPrimaryZone -Name '$PrimaryZone' -ZoneFile '$PrimaryZone.dns'" -ForegroundColor Gray
}

# 4. DNS 로깅 활성화
Write-Host "`n4. DNS 로깅 활성화..." -ForegroundColor Yellow
Set-DnsServerDiagnostics -Queries $true -QueryLog $true -PassThru | Out-Null
Write-Host "   ✓ DNS 쿼리 로깅 활성화" -ForegroundColor Green
Write-Host "   로그 위치: C:\Windows\System32\dns\dns.log" -ForegroundColor Cyan

# 5. 방화벽 규칙 확인
Write-Host "`n5. 방화벽 규칙 확인..." -ForegroundColor Yellow
$vpmRule = Get-NetFirewallRule -DisplayName "Allow DNS*from VPN*" -ErrorAction SilentlyContinue
if ($vpmRule) {
    Write-Host "   ✓ VPN DNS 방화벽 규칙 존재" -ForegroundColor Cyan
} else {
    Write-Host "   ! VPN DNS 방화벽 규칙 생성 권장" -ForegroundColor Yellow
    Write-Host "     명령: New-NetFirewallRule -DisplayName 'Allow DNS from VPN' -Direction Inbound -Protocol UDP,TCP -LocalPort 53 -RemoteAddress 10.21.0.0/24 -Action Allow" -ForegroundColor Gray
}

# 6. 최종 확인
Write-Host "`n=== 생성된 영역 목록 ===" -ForegroundColor Green
Get-DnsServerZone | Where-Object {$_.ZoneName -in @("resolver.arpa", "some.company", $PrimaryZone)} | 
    Format-Table ZoneName, ZoneType, IsAutoCreated, IsDsIntegrated -AutoSize

Write-Host "`n=== 설정 완료 ===" -ForegroundColor Green
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. OpenVPN 게이트웨이 설정 적용" -ForegroundColor Gray
Write-Host "2. iOS VPN 재연결" -ForegroundColor Gray
Write-Host "3. nslookup docs.$PrimaryZone 테스트" -ForegroundColor Gray
```

---

## 부록 B: 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2026-01-13 | 1.0 | 초안 작성 | Tech Team |

---

**문서 끝**