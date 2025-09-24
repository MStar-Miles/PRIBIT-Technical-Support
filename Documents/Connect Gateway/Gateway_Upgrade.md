**TOC (Table Of Contents)**
<!-- TOC start  -->
- [prerequisites](#prerequisites)
- [upgrade-steps](#upgrade-steps)
    - [설치 스크립트 start-wizard.sh 실행](#설치-스크립트-start-wizardsh-실행)
    - [PCG 버전 업그레이드 진행](#pcg-버전-업그레이드-진행)
    - [PCG Process 확인](#pcg-process-확인)
- [troubleshooting](#troubleshooting)

<!-- TOC end -->

<br>

💡본 문서는 PRIBIT Connect Gateway(이하 'PCG')의 버전 업그레이드 방법을 안내합니다. 

설치 버전 : `2.6.4.0` -> 업그레이드 버전 : `2.6.5.0`

<br>

## prerequisites
- 파일 업로드 

<br>

## upgrade-steps
- 설치를 진행 할 계정을 root 로 변경해줍니다. 
- 설치 시작 위치에 패키지 파일을 준비해 놓습니다. 
- deb로 압축된 패키지를 지정된 디렉토리에 압축 해제하는 과정입니다. 

<br>

`dpkg` 명령어를 실행하여 패키지를 설치합니다. 

```
# dpkg -i PRIBIT-Connect-Gateway_[VERSION].deb
(Reading database ... 121543 files and directories currently installed.)
Preparing to unpack PRIBIT-Connect-Gateway_2.6.5.0.deb ...
Unpacking pribit-connect-gateway (2.6.5.0) over (2.6.4.0) ...
Setting up pribit-connect-gateway (2.6.5.0) ...
```

<br>

`deb` 패키지를 설치하면 `/usr/local/pribit/wizard/` 경로에 다음과 같은 파일이 생성됩니다. 
```
# cd /usr/local/pribit/wizard/
# ls
archives  archives_24.04  default-config  src-compile  start-wizard.sh  
```

<br>

PCG 업그레이드 또한 `start-wizard.sh` 스크립트를 실행하여 진행합니다.   

- 업그레이드 시에는 `--update` 옵션을 주어 실행합니다.  

<br>

#### 설치 스크립트 start-wizard.sh 실행 

`./start-wizard.sh --update` 명령어를 실행합니다. 

``` 
# ./start-wizard.sh --update 
```

>[!NOTE]  
> 
>인터넷(외부 네트워크)이 연결된 환경에서 실행해야 합니다.

<br>

#### PCG 버전 업그레이드 진행 

실행 로그 
```
# ./start-wizard.sh --update
remove unused package
Reading package lists... Done
Building dependency tree
Reading state information... Done
Package 'ftp' is not installed, so not removed
Package 'telnet' is not installed, so not removed
Package 'tftpd-hpa' is not installed, so not removed
Package 'nis' is not installed, so not removed
Package 'tftpd' is not installed, so not removed
Package 'git' is not installed, so not removed
Package 'libssl-dev' is not installed, so not removed
Package 'snapd' is not installed, so not removed
Package 'ufw' is not installed, so not removed
Package 'atftpd' is not installed, so not removed
0 upgraded, 0 newly installed, 0 to remove and 64 not upgraded.
Reading package lists... Done
Building dependency tree
Reading state information... Done
0 upgraded, 0 newly installed, 0 to remove and 64 not upgraded.
Reading package lists... Done
Building dependency tree
Reading state information... Done
install PacketGo Gateway
Hit:1 http://archive.ubuntu.com/ubuntu focal InRelease
Hit:2 https://packages.redis.io/deb focal InRelease
Hit:3 http://archive.ubuntu.com/ubuntu focal-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu focal-backports InRelease
Hit:5 http://archive.ubuntu.com/ubuntu focal-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree
Reading state information... Done
lsb-release is already the newest version (11.1.0ubuntu2).
curl is already the newest version (7.68.0-1ubuntu2.25).
gpg is already the newest version (2.2.19-3ubuntu2.5).
0 upgraded, 0 newly installed, 0 to remove and 64 not upgraded.
deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb focal main
Hit:1 https://packages.redis.io/deb focal InRelease
Hit:2 http://archive.ubuntu.com/ubuntu focal InRelease
Hit:3 http://archive.ubuntu.com/ubuntu focal-updates InRelease
Hit:4 http://archive.ubuntu.com/ubuntu focal-backports InRelease
Hit:5 http://archive.ubuntu.com/ubuntu focal-security InRelease
Reading package lists... Done
Reading package lists... Done
Building dependency tree
Reading state information... Done
autoconf is already the newest version (2.69-11.1).
bison is already the newest version (2:3.5.1+dfsg-1).
cron is already the newest version (3.0pl1-136ubuntu1).
flex is already the newest version (2.6.4-6.2).
gettext is already the newest version (0.19.8.1-10build1).
libjsoncpp-dev is already the newest version (1.7.4-3.1ubuntu2).
libpam-pwquality is already the newest version (1.4.2-1build1).
libtool-bin is already the newest version (2.4.6-14).
logrotate is already the newest version (3.14.0-4ubuntu3).
python3 is already the newest version (3.8.2-0ubuntu2).
rdate is already the newest version (1:1.10-2).
bwm-ng is already the newest version (0.6.2-1).
fail2ban is already the newest version (0.11.1-1).
gperf is already the newest version (3.1-1build1).
libbotan-2-dev is already the newest version (2.12.1-2build1).
libcrypto++-dev is already the newest version (5.6.4-9build1).
libhiredis-dev is already the newest version (0.14.0-6).
libnetfilter-queue-dev is already the newest version (1.0.3-1).
libtss2-tcti-tabrmd0 is already the newest version (2.3.1-1).
libwolfssl-dev is already the newest version (4.3.0+dfsg-2).
shc is already the newest version (4.0.3-0.1).
apparmor-utils is already the newest version (2.13.3-7ubuntu5.4).
build-essential is already the newest version (12.8ubuntu1.1).
cmake is already the newest version (3.16.3-1ubuntu1.20.04.1).
isc-dhcp-server is already the newest version (4.4.1-2.1ubuntu5.20.04.5).
keepalived is already the newest version (1:2.0.19-2ubuntu0.2).
libatomic1 is already the newest version (10.5.0-1ubuntu1~20.04).
libgcrypt20-dev is already the newest version (1.8.5-5ubuntu1.1).
libgd-dev is already the newest version (2.2.5-5.2ubuntu2.4).
libgmp-dev is already the newest version (2:6.2.0+dfsg-4ubuntu0.1).
libpcre3-dev is already the newest version (2:8.39-12ubuntu0.1).
libxml2-dev is already the newest version (2.9.10+dfsg-5ubuntu0.20.04.10).
rsyslog is already the newest version (8.2001.0-1ubuntu1.3).
snmp is already the newest version (5.8+dfsg-2ubuntu2.9).
snmpd is already the newest version (5.8+dfsg-2ubuntu2.9).
uuid-dev is already the newest version (2.34-0.1ubuntu9.6).
zlib1g-dev is already the newest version (1:1.2.11.dfsg-2ubuntu1.5).
netfilter-persistent is already the newest version (1.0.14ubuntu1).
openjdk-17-jre-headless is already the newest version (17.0.15+6~us1-0ubuntu1~20.04).
redis-server is already the newest version (6:8.0.3-1rl1~focal1).
0 upgraded, 0 newly installed, 0 to remove and 64 not upgraded.
fn_compile_shellscript
compile 3rd-party source
Configuring OpenSSL version 3.3.4 for target linux-x86_64
Using os-specific seed configuration
Created configdata.pm
Running configdata.pm
Created Makefile.in
Created Makefile
Created include/openssl/configuration.h

**********************************************************************
***                                                                ***
***   OpenSSL has been successfully configured                     ***
***                                                                ***
***   If you encounter a problem while building, please open an    ***
***   issue on GitHub <https://github.com/openssl/openssl/issues>  ***
***   and include the output from the following command:           ***
***                                                                ***
***       perl configdata.pm --dump                                ***
***                                                                ***
***   (If you are new to OpenSSL, you might want to consult the    ***
***   'Troubleshooting' section in the INSTALL.md file first)      ***
***                                                                ***
**********************************************************************

...
(중략)
... 

[2025-09-24T14:38:58,620] [main] INFO GatewayUtil -- createEncryptFile
[2025-09-24T14:38:58,660] [main] INFO GatewayUtil -- createResourceFile path : /var/connect/gateway/system-integrity/encrypt.pgd
[2025-09-24T14:38:59,560] [main] INFO GatewayUtil -- createResourceFile path : /var/connect/gateway/system-integrity/repository.pgd
[2025-09-24T14:38:59,575] [main] INFO GatewayUtil -- createResourceFile path : /var/connect/gateway/system-integrity/inmemorydb.pgd
[2025-09-24T14:38:59,576] [main] INFO GatewayUtil -- ####################################################################################################
[2025-09-24T14:38:59,577] [main] INFO GatewayUtil -- gateway.serial=a9f41476-553a-412a-9f46-ccf9b93c9def
[2025-09-24T14:38:59,577] [main] INFO GatewayUtil -- ####################################################################################################
[2025-09-24T14:38:59,578] [main] INFO GatewayUtil --
[2025-09-24T14:38:59,578] [main] INFO GatewayUtil --
fn_ipsec_conf
Profile for /usr/lib/ipsec/charon not found, skipping
Profile for /usr/lib/ipsec/stroke not found, skipping
Profile for /usr/sbin/swanctl not found, skipping
--- charon-logging config backup ---
ipsec cert, config create
========================================================
        PacketGo Gateway Install was completed.
========================================================
```

<br>

#### PCG Process 확인 
- 설치가 정상적으로 완료되면 PCG 가 자동으로 실행되도록 되어 있습니다.
- 모든 모듈이 정상적으로 기동되었는지 확인합니다. 
- 자세한 확인 방법은 [Gateway_Installation의 3. PCG Process 확인](../Connect%20Gateway/Gateway_Installation.md#3-pcg-process-확인) 항목을 참고하세요.

<br><br>

## troubleshooting
