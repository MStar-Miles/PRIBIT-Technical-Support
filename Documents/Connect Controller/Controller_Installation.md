# PRIBIT Connect Controller Installation

💡본 문서는 PRIBIT Connect Controller(이하 'PCC')의 단계별 설치 방법을 안내합니다.

설치 버전 : `2.6.4.3`


## Prerequisites

- 설치 환경([Prerequisites](./Prerequisites.md)) 준비
- 시스템 구성([System Architecture](/Documents/Architecture/architecture.md)) 확인 

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

    #### install_offline.sh
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
    ```
    `./install_offline.sh` 명령어를 실행합니다. 

    <br><br>

3. **PCC DataBase 설치**
    - PCC 가 사용할 Database를 설치합니다. 
    
    <br><br>

    ```    
    Enter DBMS root new password: [패스워드 입력]
    Re-enter DBMS root new password: [패스워드 재입력]
    =========================================================================================
    ``` 
    Database 의 root 계정 패스워드를 입력합니다. 
    
    _(root 계정 패스워드 Pribit2560!)_
    
    <br><br>
    
    ```
    Create database User : pribit
    Enter pribit new password: [패스워드 입력]
    Re-enter pribit new password: [패스워드 입력]
    ```
    Database User 를 생성하고 계정의 패스워드를 입력합니다. 

    _(계정: pribit / 패스워드: Packetgo2560!)_

    <br><br>
    
    ```
    =========================================================================================
    Enter Allowed IP for PRIBIT Connect Controller : [접근 허용 IP Address]
    Re-enter Allowed IP for PRIBIT Connect Controller : [접근 허용 IP Address]
    ```
    설치되는 PRIBIT Connect Controller 관리자 페이지에  접속 허용 할 IP Address 정보를 입력합니다. 
    
    _(모두 허용 (All allow) 시: 0.0.0.0)_

    <br><br>

    ```
    Build-Essential
    ```
    PCC 실행에 필요한 라이브러리들을 설치합니다.

    <br><br>

    ```
    =========================================================================================
    [2025-08-11T18:27:53,590] [INFO] PCC Start Setup......
    [2025-08-11T18:28:03,581] [INFO] PCC Setup Completed......
    2025-08-11 18:28:03 | make properties files SUCCESS
    =========================================================================================
    2025-08-11 18:28:03 | remove install files
    =========================================================================================
    2025-08-11 18:28:05 | remove install files SUCCESS
    =========================================================================================
    2025-08-11 18:28:05 | Start PRIBIT Connect Controller
    [2025-08-11T18:28:16,218] [INFO] PCC Legacy Table Setting Start......
    [2025-08-11T18:28:16,511] [INFO] Already setting TB_EVDC and TB_EVDC_LEGACY SUCCESS
    [2025-08-11T18:28:16,573] [INFO] Already setting TB_CORE_USER_ACT_LOG and TB_CORE_USER_ACT_LEGACY_LOG SUCCESS
    [2025-08-11T18:28:16,574] [INFO] PCC Legacy Table Setting Completed......
    =========================================================================================
    2025-08-11 18:29:39 | The installation was completed normally.
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

4. **Connect Controller Process 확인**
    - 설치가 정상적으로 완료되면 PCC 가 자동으로 실행되도록 되어 있습니다.
    - 모든 모듈이 정상적으로 기동되었는지 확인합니다. 

    - Process 확인
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

    - Port 확인 
        - TCP PORT 443: 
        - TCP PORT 5996: 
        - TCP PORT 5997: 
        - TCP PORT 5999: 
    ```
    # netstat -an | grep 5996
    root@connect-controller:/opt/connect/logs# netstat -an | grep -E '443'\|'5996'\|'5997'\|'5999'
    tcp        0      0 0.0.0.0:5997            0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:5996            0.0.0.0:*               LISTEN     
    tcp6       0      0 127.0.0.1:5999          :::*                    LISTEN
    ```

    <br><br>

5. **초기 설정 및 라이선스 적용**
    - PCC 가 정상적으로 기동되면 관리자 PC 에서 PCC Console 에 접속하여 라이선스를 적용합니다. 
    - 초기 설정([사용자 메뉴얼](/Documents/Connect%20Controller/UserManual.md)) 및 라이선스 적용([라이선스 적용](/Documents/Connect%20Controller/License.md))은 관련 문서를 참고하세요. 


## Troubleshooting

- If the controller does not power on, check the power connections. 
- For network issues, verify cable connections and network settings. 

## Support

For further assistance, contact technical support.
