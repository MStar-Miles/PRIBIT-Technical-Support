# IPSec Site-to-Site VPN 구축 가이드 

Pribit Connect Gateway 를 이미 설치 완료한 상태입니다. 


> [!NOTE] 
> On-Prem 장비로 설치 시 PRIBIT 에서 제공하는 ISO (Ubuntu 24.04.02 Custom ISO)를 사용하여 설치합니다.  
> AWS, AZURE, GCP 등 일반 VM(Instance) 에 설치 시 Ubuntu 24.04 에서는 Strong-Swan 이 정상적으로 기동되지 않습니다.   
> 아래 커널 버전을 확인 후 필요한 커널 모듈을 설치해주어야 합니다.  

### 커널 모듈 재설치

```bash
# 현재 커널 모듈 재설치
sudo apt-get install --reinstall linux-modules-$(uname -r)
sudo apt-get install linux-modules-extra-$(uname -r)

# depmod 실행
sudo depmod -a

# 재부팅
sudo reboot
```

--- 

## 구조 및 네트워크 이해

Site - to - Site 구조는 다음과 같은 형태를 말합니다. 

Core Gateway
 - 중앙 허브로 여러 사이트(예를들어 DEU, USA, AFC 등)를 연결 
 - 내부망으로 라우팅 역할 

Edge Gateway 
 - VPN 클라이언트 접속 게이트웨이로 사용자가 접속할 지역에 위치 
 - 중앙 Core Gateway 와 Site-to-Site (IPSec) 연결하여 내부 네트워크에 접속 

--- 

## 설정 파일 구조 결정  

각 설정파일은 다음과 같습니다. 

### 최종 구조  
```
Core Gateway:
  /usr/local/etc/ipsec.d/conn/
    └── core.conf       # Site-to-Site (conn deu, namc, afc) 

DEU Gateway:
  /usr/local/etc/ipsec.d/conn/
    └── deu.conf        # Core 연결 (conn deu)     

USA Gateway:
  /usr/local/etc/ipsec.d/conn/
    └── namc.conf        # Core 연결 (conn namc)     

AFRIA Gateway:
  /usr/local/etc/ipsec.d/conn/
    └── afc.conf        # Core 연결 (conn afc)     
```

### 파일 이름 vs conn 이름  
- **파일 이름**: 관리 편의용 (core.conf, deu.conf)  
- **conn 이름**: StrongSwan이 실제 사용 (conn deu)  
- `ipsec.conf`에 `include ipsec.d/conn/*.conf` 설정 필요 (나머지 설정은 제거, 예)c_default.conf, c_site.conf) 

---

## Left/Right 설정

```conf
# Core (core.conf)
conn deu
    left=10.156.11.91              # Core private IP
    leftsubnet=10.156.11.0/24,...  # Core 내부망
    right=35.159.88.134            # DEU public IP
    rightsubnet=10.156.96.0/24     # DEU VPN 대역

# DEU (deu.conf)
conn deu
    left=%any                      # AWS NAT 뒤 (DEU public IP) 
    leftsubnet=10.156.96.0/24      # DEU VPN 대역
    right=203.229.165.213          # Core public IP
    rightsubnet=10.156.11.0/24,... # Core 내부망
```

---

## 인증서 관리

### 현재 인증서 구조
```
CA: ca.pqc.packetgo.com (Private Key 존재) 
Gateway 인증서: gateway.pqc.packetgo.com (모든 Gateway 공유) 
```

### 개별 인증서 발급 시도
- 개별 인증서 발급이 현재 안됨 
- OpenSSL 3.x에서 RSA 키 생성 오류 발생
- `genpkey: Error generating RSA key` (provider keymgmt failure)

### 최종 적용: 기존 인증서 공유
- 모든 Gateway가 `gateway.pqc.packetgo.com` 인증서 사용
- ID도 인증서 CN과 일치: `@gateway.pqc.packetgo.com`

#### Core 에서 각 Edge 로 인증서 전송

```bash
# Core Gateway에서
cd ~
mkdir edge-deploy
cd edge-deploy

# 필요한 파일 복사 (cacerts, certs, private, secrets)
cp /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem ./
cp /usr/local/etc/ipsec.d/certs/gateway.pqc.packetgo.com.cert.pem ./
cp /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem ./
/var/connect/connect_encrypter /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets.crypt
cp /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets ./

# 압축
cd ~
tar -czf edge-certs.tar.gz edge-deploy/

# Edge 로 전송
scp edge-certs.tar.gz root@54.193.52.182:/tmp/

# 정리
rm -rf edge-deploy edge-certs.tar.gz
```

#### Edge Gateway 에 설치

```bash
# Edge Gateway에서
cd /tmp
tar -xzf edge-certs.tar.gz
cd edge-deploy

# 기존 파일 백업 (있다면)
sudo cp /usr/local/etc/ipsec.d/certs/gateway.pqc.packetgo.com.cert.pem \ 
    /usr/local/etc/ipsec.d/certs/gateway.pqc.packetgo.com.cert.pem.back 
sudo cp /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem \ 
    /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem.back  
sudo cp /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem \ 
    /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem.back  
sudo cp /usr/local/etc/ipsec.d/secrets/ca.pqc.packetgo.com.cert.pem \ 
    /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem.back  
sudo cp /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets.crypt \ 
    /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets.crypt.back 

# 설치
sudo cp ca.pqc.packetgo.com.cert.pem /usr/local/etc/ipsec.d/cacerts/
sudo cp gateway.pqc.packetgo.com.cert.pem /usr/local/etc/ipsec.d/certs/
sudo cp gateway.pqc.packetgo.com.key.pem /usr/local/etc/ipsec.d/private/
sudo cp gateway.pqc.packetgo.com.secrets /usr/local/etc/ipsec.d/secrets/
sudo /var/connect/connect_encrypter /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets 

# /var/connect/connect_encrypter /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets 를 수행하면 gateway.pqc.packetgo.com.secrets.crypt 파일이 생성됩니다. 

# 권한 설정
sudo chmod 700 /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem
sudo chmod 700 /usr/local/etc/ipsec.d/certs/gateway.pqc.packetgo.com.cert.pem
sudo chmod 700 /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem
sudo chmod 700 /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets/gateway.pqc.packetgo.com.secrets.crypt 

# 소유자 설정
sudo chown root:root /usr/local/etc/ipsec.d/cacerts/ca.pqc.packetgo.com.cert.pem
sudo chown root:root /usr/local/etc/ipsec.d/certs/gateway.pqc.packetgo.com.cert.pem
sudo chown root:root /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem
sudo chown root:root /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets.crypt

# 정리
cd /tmp
rm -rf edge-deploy edge-certs.tar.gz
```

#### StrongSwan 재시작

``` 
# NAMC Gateway에서
sudo systemctl restart strongswan-starter

# 인증서 확인
sudo ipsec listcerts

# 연결 시도
sudo ipsec up deu
sudo ipsec up namc
sudo ipsec up afc

# 상태 확인
sudo ipsec statusall
``` 

---

### ID 설정 이슈

#### 시도: 각 Gateway별 고유 ID
```conf
leftid=@core-gateway.pqc.packetgo.com
leftid=@deu-gateway.pqc.packetgo.com
```
→ **실패**: `AUTHENTICATION_FAILED` (인증서 CN과 불일치)

#### 해결: ID를 인증서 CN과 일치
```conf
leftid=@gateway.pqc.packetgo.com
rightid=@gateway.pqc.packetgo.com
```
→ **성공**: 연결 수립

---  

## 최종 설정

### Core Gateway - core.conf
```conf
conn deu
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=10.156.11.91
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    leftauth=pubkey
    
    right=35.159.88.134
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.96.0/24
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256

conn namc
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=10.156.11.91
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    leftauth=pubkey
    
    right=54.193.52.182
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.95.0/24
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256

conn afc
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=10.156.11.91
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    leftauth=pubkey
    
    right=13.247.84.73
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.94.0/24
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256
```

### DEU Gateway - deu.conf
```conf
conn deu
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=%any
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.96.0/24
    leftauth=pubkey
    
    right=203.229.165.213
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256
```

### USA Gateway - namc.conf
```conf  
conn namc
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=%any
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.95.0/24
    leftauth=pubkey
    
    right=203.229.165.213
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256
``` 
--- 

### AFRICA Gateway - afc.conf
```conf  
conn afc
    auto=start
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=%any
    leftid=@gateway.pqc.packetgo.com
    leftcert=gateway.pqc.packetgo.com.cert.pem
    leftsubnet=10.156.94.0/24
    leftauth=pubkey
    
    right=203.229.165.213
    rightid=@gateway.pqc.packetgo.com
    rightsubnet=10.156.11.0/24,10.156.51.0/24,10.100.2.0/24,203.229.165.232/32
    rightauth=pubkey
    
    ike=aes256-sha256-mlkem768
    esp=aes256-sha256
```  
---  

## 성공 확인

```
IKE_SA deu[99] established between 
  10.156.11.91[gateway.pqc.packetgo.com]...35.159.88.134[gateway.pqc.packetgo.com]

IKE proposal: AES_CBC_256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/ML_KEM_768

CHILD_SA deu{84} established
  TS: 10.100.2.0/24 10.156.11.0/24 10.156.51.0/24 203.229.165.232/32 === 10.156.96.0/24

connection 'deu' established successfully
```
---

## 관리 명령어

```bash
# 상태 확인
sudo ipsec statusall
sudo ipsec status deu

# 연결 제어
sudo ipsec up deu
sudo ipsec down deu
sudo ipsec reload

# 로그
sudo journalctl -u strongswan-starter -f
```