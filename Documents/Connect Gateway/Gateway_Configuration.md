# PRIBIT VPN Gateway Configuration

💡Gateway Configuration 파일(server.conf)은 PRIBIT Connect VPN Gateway 서버 설정을 관리합니다. 
이 페이지에서는 설정 파일 위치 및 주요 설정 값을 안내합니다. 

<br>

⚙️ **설정 파일 위치**  

OS: Linux Ubuntu 20.04.6 LTS : _**/var/connect/connect-vpn/conf/server.conf**_ 

<br>

## Gateway 세부 설정

| **설정** | **설명** | **값** | **범위** |
| ---: | :--- | :--- | --- |
| `port`  | VPN 서버가 사용하는 포트 번호 | 443 |  |
| `porto` | 사용하는 프로토콜 유형 (TCP 또는 UDP) | tcp |  |
| `dev` | 사용할 가상 네트워크 인터페이스 유형 | tun |  |
| `keepalive` | 연결 유지를 위한 핑 간격(초) 및 타임아웃(초) 설정 | 10 60  |  |
| `persist-key` | VPN 재시작 시 키를 다시 읽지 않도록 유지 | (blank) |  |
| `persist-tun` | VPN 재시작 시 TUN/TAP 장치를 다시 열지 않도록 유지 | (blank) |  |
| `tun-mtu` | TUN 인터페이스의 최대 전송 단위 크기(바이트) | 1500 |  |
| `mssfix` | TCP 세션의 최대 세그먼트 크기 제한(바이트) | 1380 |  |
| `auth-nocache` | 인증 정보를 메모리에 캐싱하지 않음 | (blank) |  |
| `remote-cert-tls` | 원격 인증서 확인 방식 설정 | server |  |
| `tls-ciphersuites`  | TLS 연결에 사용할 암호화 스위트 목록 | TLS_AES_256_GCM_SHA384:<br>TLS_MCARIA_256_CTR_MCSHA256 |  |
| `data-ciphers` | 데이터 암호화에 사용할 암호화 알고리즘 목록 | aes-256-gcm:<br>aes-256-cbc:<br>aes-256-ctr:<br>MC-ARIA-256-CBC:<br>MC-ARIA-256-CTR:<br>chacha20-poly1305 |  |
| `auth` | 패킷 인증에 사용할 해시 알고리즘 | MC-SHA256 |  |
| `tls-server` | TLS 서버 모드로 작동 | (blank) |  |
| `verb` | 로그 상세 수준 (높을수록 더 자세한 로그) | 3 |  |
| `providers` | 사용할 암호화 프로바이더 목록 | default oqsprovider |  |
| `tls-groups` | TLS 키 교환에 사용할 그룹 목록 | X25519:mc-p256r1:kyber512 |  |
| `username-as-common-name` | 인증서 대신 사용자 이름을 Common Name으로 사용 | (blank) |  |
| `max-clients` | 동시 접속 가능한 최대 클라이언트 수 | 10,000 |  |
| `topology` | VPN 네트워크 토폴로지 구성 방식 | subnet |  |
| `server` | VPN 서버 IP 주소 범위 및 서브넷 마스크 | 10.21.0.0 255.255.255.0 |  |
| `script-security` | 스크립트 실행 보안 수준 설정 | 3 |  |
| `auth-user-pass-verify` | 사용자 인증 검증을 위한 스크립트 파일 및 방식 | “/var/connect/connect-vpn/script/verify.sh” via-file |  |
| `client-config-dir` | 클라이언트별 구성 파일이 저장된 디렉토리 | /var/connect/connect-vpn/static-ips |  |
| `client-to-client` | 클라이언트 간 직접 통신 허용 | (blank) |  |
| `ca` | 인증 기관(CA) 인증서 파일 경로 | /var/connect/connect-vpn/cacerts/ca.crt |  |
| `cert` | 서버 인증서 파일 경로 | /var/connect/connect-vpn/cacerts/server.crt |  |
| `key` | 서버 개인 키 파일 경로 | /var/connect/connect-vpn/cacerts/server.key |  |
| `askpass` | 개인 키 암호를 저장한 파일 경로 | /var/connect/connect-vpn/cacerts/certfile |  |
| `dh` | Diffie-Hellman 매개변수 파일 (none은 ECDHE 사용) | none |  |
| `status` | VPN 상태 로그 파일 경로 | /var/connect/connect-vpn/log/connect-vpn-status.log |  |
| `log` | VPN 일반 로그 파일 경로 | /var/connect/connect-vpn/log/connect-vpn.log |  |
| `push` | 클라이언트에 전달할 네트워크 라우팅 정보 | “route 10.200.0.0 255.255.255.0” |  |