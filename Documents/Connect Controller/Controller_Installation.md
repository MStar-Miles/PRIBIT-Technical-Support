**TOC (Table Of Contents)**
<!-- TOC start  -->
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Troubleshooting](#troubleshooting)
- [Support](#support)

<!-- TOC end -->

<br>

💡본 문서는 PRIBIT Connect Controller(이하 'PCC')의 단계별 설치 방법을 안내합니다.

설치 버전 : `2.6.4.3`

<br>

## Prerequisites

- 설치 환경([Prerequisites](./Prerequisites.md)) 준비
- 시스템 구성([System Architecture](/Documents/Architecture/architecture.md)) 확인 

<br><br>

## Installation Steps

1. **PCC Package 압축 해제** 
    - 설치를 진행 할 계정을 root 로 변경해줍니다. 
    - 설치 시작 위치에 패키지 파일을 준비해 놓습니다. 
    - deb로 압축된 패키지를 지정된 디렉토리에 압축 해제하는 과정입니다. 

    <br><br>

    ```
    # dpkg -i PRIBIT-Connect-Controller-Focal_[VERSION].deb

    Selecting previously unselected package pribit-connect-controller.
    (Reading database ... 145175 files and directories currently installed.)
    Preparing to unpack PRIBIT-Connect-Controller-Focal_[VERSION].deb ...
    Unpacking pribit-connect-controller ([VERSION]) ...
    Setting up pribit-connect-controller ([VERSION]) ...
    ```
    `dpkg` 명령어를 실행하여 패키지를 설치합니다. 

    <br><br>

    ```
    # cd /usr/local/pribit/connect/services
    # ls -al
    drwxrwxr-x  7 pribit pribit  4096 Aug 11 08:06 .
    drwxrwxr-x  3 pribit pribit  4096 Aug 11 08:06 ..
    drwxrwxr-x  2 pribit pribit  4096 Aug 11 08:06 ctrl
    -rwxrwxr-x  1 pribit pribit 59473 Aug  5 06:27 install_offline.sh
    -rwxrwxr-x  1 pribit pribit 62237 Aug  5 06:27 install_online.sh
    drwxrwxr-x  2 pribit pribit  4096 Aug 11 08:06 mysql
    drwxrwxr-x  2 pribit pribit  4096 Aug 11 08:06 nginx
    drwxrwxr-x  2 pribit pribit  4096 Aug 11 08:06 sys
    drwxrwxr-x 23 pribit pribit  4096 Aug 11 08:06 thirdparty-packages
    ```
    `deb` 패키지를 설치하면 `/usr./local/pribit/connect/service/` 경로에 다음과 같은 파일이 생성됩니다. 

    <br><br>

2. **PCC 설치**
    - PCC 설치 방식에는 `install_offline.sh`와 `install_online.sh` 두 가지 옵션이 있습니다.  
    - `install_offline.sh` 설치 방식
        - 인터넷 네트워크와 연결이 없는 Offline 으로 설치를 진행합니다. 
    - `install_online.sh' 설치 방식 
        - 인터넷 네트워크와 연결된 Online 으로 설치를 진행합니다. 

    <br><br>

    #### 설치 스크립트 install_offline.sh 실행
    ``` 
    # ./install_offline.sh 
    =========================================================================================
    2025-08-11 08:24:00 | Installing PRIBIT Connect Controller
    2025-08-11 08:24:00 | The installation process is saved in a log file
    2025-08-11 08:24:00 | log file path '/opt/connect/logs/connect-controller-install.log'
    2025-08-11 08:24:00 | This OS is Ubuntu 20.04.6 LTS
    =========================================================================================
    2025-08-11 08:24:00 | OS Auto Update Disable Setting
    =========================================================================================
    2025-08-11 08:24:00 | modify /etc/apt/apt.conf.d/10periodic
    2025-08-11 08:24:00 | modify /etc/apt/apt.conf.d/20auto-upgrades
    2025-08-11 08:24:00 | disable apt-daily.timer
    2025-08-11 08:24:01 | disable apt-daily-upgrade.timer
    =========================================================================================
    2025-08-11 08:24:01 | OS Auto Update Disable Setting SUCCESS
    =========================================================================================
    (Continue)
    ```
    `./install_offline.sh` 명령어를 실행합니다. 

    <br><br>

    #### PCC 가 사용할 Database 설치    
    ```    
    Enter DBMS root new password: [패스워드 입력]
    Re-enter DBMS root new password: [패스워드 재입력]
    =========================================================================================
    (Continue)
    ``` 
    Database 의 root 계정 패스워드를 입력합니다. 
    
    _(root 계정 패스워드 Pribit2560!)_
    
    <br><br>
    
    ```
    Create database User : pribit
    Enter pribit new password: [패스워드 입력]
    Re-enter pribit new password: [패스워드 입력]
    (Continue)
    ```
    Database User 를 생성하고 계정의 패스워드를 입력합니다. 

    _(계정: pribit / 패스워드: Packetgo2560!)_

    <br><br>
    
    #### PCC Console 에 접근 허용할 IP Address 설정
    ```
    =========================================================================================
    Enter Allowed IP for PRIBIT Connect Controller : [접근 허용 IP Address]
    Re-enter Allowed IP for PRIBIT Connect Controller : [접근 허용 IP Address]
    (Continue)
    ```
    설치되는 PRIBIT Connect Controller 관리자 페이지에  접속 허용 할 IP Address 정보를 입력합니다. 
    
    _(모두 허용 (All allow) 시: 0.0.0.0)_

    <br><br>

    #### PCC 에서 사용하는 라이브러리 설치 
    ```
    =========================================================================================
    2025-08-12 02:25:23 | apt-get update
    2025-08-12 02:25:23 | OFF-LINE mode do not need apt-get update
    =========================================================================================
    2025-08-12 02:25:23 | net-tools install
    2025-08-12 02:25:23 | net-tools already installed.
    =========================================================================================
    2025-08-12 02:25:23 | rdate install
    2025-08-12 02:25:29 | rdate installation                                     
    2025-08-12 02:25:29 | rdate install SUCCESS
    =========================================================================================
    2025-08-12 11:25:30 | timezone is 'Asia/Seoul'
    2025-08-12 11:25:30 | time server is 'time.bora.net'
    =========================================================================================
    2025-08-12 11:25:30 | rsyslog setting
    2025-08-12 11:25:31 | rsyslog setting SUCCESS
    =========================================================================================
    2025-08-12 11:25:31 | check service
    2025-08-12 11:25:31 | check service SUCCESS
    =========================================================================================
    2025-08-12 11:25:32 | openjdk-17-jre install
    2025-08-12 11:26:22 | openjdk-17-jre installation                                     
    2025-08-12 11:26:22 | openjdk-17-jre install SUCCESS
    =========================================================================================
    2025-08-12 11:26:22 | build-essential install
    2025-08-12 11:27:16 | build-essential installation                                     
    2025-08-12 11:27:16 | build-essential install SUCCESS
    =========================================================================================
    2025-08-12 11:27:16 | libpcre3-dev install
    2025-08-12 11:27:26 | libpcre3-dev installation                                     
    2025-08-12 11:27:26 | libpcre3-dev install SUCCESS
    =========================================================================================
    2025-08-12 11:27:26 | zlib1g-dev install
    2025-08-12 11:27:32 | zlib1g-dev installation                                     
    2025-08-12 11:27:32 | zlib1g-dev install SUCCESS
    =========================================================================================
    2025-08-12 11:27:32 | libssl-dev install
    2025-08-12 11:27:33 | libssl-dev installation                                     
    2025-08-12 11:27:33 | libssl-dev already installed
    =========================================================================================
    2025-08-12 11:27:34 | libgd-dev install
    2025-08-12 11:28:01 | libgd-dev installation                                     
    2025-08-12 11:28:01 | libgd-dev install SUCCESS
    =========================================================================================
    2025-08-12 11:28:01 | libxml2-dev install
    2025-08-12 11:28:14 | libxml2-dev installation                                     
    2025-08-12 11:28:14 | libxml2-dev install SUCCESS
    =========================================================================================
    2025-08-12 11:28:14 | apt-transport-https install
    2025-08-12 11:28:19 | apt-transport-https installation                                     
    2025-08-12 11:28:19 | apt-transport-https install SUCCESS
    =========================================================================================
    2025-08-12 11:28:19 | expect install
    2025-08-12 11:28:30 | expect installation                                     
    2025-08-12 11:28:30 | expect install SUCCESS
    =========================================================================================
    2025-08-12 11:28:30 | mariadb add apt repository Setting
    2025-08-12 11:28:30 | OFF-LINE mode do not need add mariadb apt repository Setting
    =========================================================================================
    2025-08-12 11:28:30 | mariadb-server install
    2025-08-12 11:28:58 | mariadb-server installation                                     
    2025-08-12 11:28:58 | mariadb-server install SUCCESS
    =========================================================================================
    2025-08-12 11:28:58 | mariadb-backup install
    2025-08-12 11:29:07 | mariadb-backup installation                                     
    2025-08-12 11:29:07 | mariadb-backup install SUCCESS
    =========================================================================================
    2025-08-12 11:29:08 | mysql_secure_installation
    2025-08-12 11:29:10 | mysql_secure_installation SUCCESS
    =========================================================================================
    2025-08-12 11:29:11 | PRIBIT Connect Controller DataBase Setting
    2025-08-12 11:29:13 | PRIBIT Connect Controller DataBase Setting SUCCESS
    =========================================================================================
    2025-08-12 11:29:14 | shc install
    2025-08-12 11:29:22 | shc installation                                     
    2025-08-12 11:29:22 | shc install SUCCESS
    =========================================================================================
    2025-08-12 11:29:22 | thirdparty-conf-set.sh to BINARY
    2025-08-12 11:29:22 | thirdparty-conf-set.sh to BINARY SUCCESS
    =========================================================================================
    2025-08-12 11:29:22 | mariadb systemd reset
    2025-08-12 11:29:29 | mariadb systemd reset SUCCESS
    =========================================================================================
    2025-08-12 11:29:29 | hostname change
    2025-08-12 11:29:29 | hostname change to connect-controller SUCCESS
    =========================================================================================
    2025-08-12 11:29:29 | systemd add connect controller service
    2025-08-12 11:29:32 | systemd add connect controller service SUCCESS
    =========================================================================================
    2025-08-12 11:29:32 | openssl build
    2025-08-12 11:37:57 | openssl configure make install                                     
    2025-08-12 11:37:57 | openssl build SUCCESS
    =========================================================================================
    2025-08-12 11:37:57 | nginx build
    2025-08-12 11:40:07 | nginx configure make install                                     
    2025-08-12 11:40:07 | nginx make install build SUCCESS
    =========================================================================================
    2025-08-12 11:40:07 | redis-server add apt repository set
    2025-08-12 11:40:08 | OFF-LINE mode do not need add redis-server apt repository set
    =========================================================================================
    2025-08-12 11:40:08 | redis-server install
    2025-08-12 11:40:48 | redis-server installation                                     
    2025-08-12 11:40:48 | redis-server install SUCCESS
    =========================================================================================
    2025-08-12 11:40:48 | redis-server add json plugin
    2025-08-12 11:40:54 | redis-server add json plugin(librejson.so)                                     
    2025-08-12 11:40:54 | redis-server add json plugin(librejson.so) SUCCESS
    =========================================================================================
    2025-08-12 11:40:54 | redis set
    2025-08-12 11:41:09 | redis setting                                     
    2025-08-12 11:41:09 | redis set SUCCESS
    =========================================================================================
    2025-08-12 11:41:09 | keepalived install
    2025-08-12 11:41:23 | keepalived installation                                     
    2025-08-12 11:41:23 | keepalived install SUCCESS
    =========================================================================================
    2025-08-12 11:41:23 | snmpd install
    2025-08-12 11:41:33 | snmpd installation                                     
    2025-08-12 11:41:33 | snmpd install SUCCESS
    =========================================================================================
    2025-08-12 11:41:33 | snmp install
    2025-08-12 11:41:38 | snmp installation                                     
    2025-08-12 11:41:38 | snmp install SUCCESS
    =========================================================================================
    2025-08-12 11:41:38 | bwm-ng install
    2025-08-12 11:41:45 | bwm-ng installation                                     
    2025-08-12 11:41:45 | bwm-ng install SUCCESS
    =========================================================================================
    (Continue)
    ```
    PCC 실행에 필요한 라이브러리들을 설치합니다.

    <br><br>

    #### PCC 설치 마무리 
    ```
    =========================================================================================
    2025-08-12 11:41:46 | file access setting
    2025-08-12 11:41:47 | file access setting SUCCESS
    =========================================================================================
    2025-08-12 11:41:48 | make properties files
    2025-08-12 11:42:00 | making properties files                                     
    2025-08-12 11:42:00 | make properties files SUCCESS
    =========================================================================================
    2025-08-12 11:42:00 | remove install files
    2025-08-12 11:42:01 | remove install files SUCCESS
    =========================================================================================
    2025-08-12 11:43:37 | Start PRIBIT Connect Controller                                     
    2025-08-12 11:43:37 | The installation was completed normally.
    =========================================================================================
    OS Version              : Ubuntu 20.04.6 LTS
    OS Kernel Version       : 5.4.0-144-generic
    Openssl Version         : v3.0.16
    Nginx Version           : v1.26.3
    OpenJDK Version         : v17.0.14
    Embedded Tomcat Version : v10.1.34
    MariaDB Version         : v10.6.21
    Redis Version           : v7.4.2
    Keepalived Version      : v2.0.19
    Snmpd Version           : v5.8
    bwm-ng Version          : v0.6.2
    =========================================================================================
    ```
    설치가 완료되면 _'The installation was completed normally.'_ 라는 메시지가 나타나며 설치 과정이 완료됩니다.

    <br><br>

3. **PCC Process 확인**
    - 설치가 정상적으로 완료되면 PCC 가 자동으로 실행되도록 되어 있습니다.
    - 모든 모듈이 정상적으로 기동되었는지 확인합니다. 

    - Process 확인
        - Web
            - controller web
            - controller api
            - controller rpc 
            - controller check 

        ```
        # ps -ef | grep controller
        root       74231       1  0 Aug11 ?        00:04:20 /usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/web/controller-web-1.0.war
        root       74380       1  0 Aug11 ?        00:03:41 /usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/api/controller-api-1.0.jar
        root       74753       1  6 Aug11 ?        01:00:32 /usr/bin/java -server -Dpgct=connect-controller -Dpgct.home=/opt/connect/controller -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms2048m -Xmx3072m -jar /opt/connect/controller/rpc/controller-rpc-1.0.jar
        root       74990       1  0 Aug11 ?        00:08:18 /usr/bin/java -Djdk.lang.Process.launchMechanism=vfork -jar /opt/connect/controller/check/controller-check-1.0.jar
        ```

        - Database / Redis 

        ```
        # ps -ef | grep -E mariadb\|redis
        redis     133681       1  0 11:41 ?        00:00:31 /usr/bin/redis-server 127.0.0.1:6379
        mysql     136330       1  0 11:42 ?        00:00:19 /usr/sbin/mariadbd
        ```

    - Web Listen Port 확인 
        - TCP PORT 443: 
        - TCP PORT 5996: 
        - TCP PORT 5997: 
        - TCP PORT 5999: 
    ```
    # netstat -an | grep -E '443'\|'5996'\|'5997'\|'5999'       
    tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:5996            0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:5997            0.0.0.0:*               LISTEN  
    tcp6       0      0 127.0.0.1:5999          :::*                    LISTEN
    ```

    <br><br>

4. **초기 설정 및 라이선스 적용**
    - PCC 가 정상적으로 기동되면 관리자 PC 에서 PCC Console 에 접속하여 라이선스 및 초기 설정을 진행합니다. 
    - [라이선스 적용](/Documents/Connect%20Controller/License.md) 및 [사용자 메뉴얼](/Documents/Connect%20Controller/UserManual.md)은 관련 페이지를 참고하세요. 

<br><br>

## Troubleshooting

- [Troubleshooting](/Documents/TroubleShooting.md) 페이지를 참고하세요.

<br><br>

## Support

*For further assistance, contact technical support team.*
