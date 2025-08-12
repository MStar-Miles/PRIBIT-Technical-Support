# Gateway Installation

💡본 문서는 PRIBIT Connect Gateway(이하 'PCG')의 단계별 설치 방법을 안내합니다.

설치 버전 : `2.6.4.0`

## Prerequisites

- 설치 환경([Prerequisites](./Prerequisites.md)) 준비
- 시스템 구성([System Architecture](/Documents/Architecture/architecture.md)) 확인 

<br><br>

## Installation Steps

1. **PCG Package 압축 해제** 
    - 설치를 진행 할 계정을 root 로 변경해줍니다. 
    - 설치 시작 위치에 패키지 파일을 준비해 놓습니다. 
    - deb로 압축된 패키지를 지정된 디렉토리에 압축 해제하는 과정입니다. 

    <br>
    
    ```
    # dpkg -i PRIBIT-Connect-Gateway_[VERSION].deb

    Selecting previously unselected package pribit-connect-gateway.
    (Reading database ... 108777 files and directories currently installed.)
    Preparing to unpack PRIBIT-Connect-Gateway_2.6.4.0.deb ...
    Unpacking pribit-connect-gateway (2.6.4.0) ...
    Setting up pribit-connect-gateway (2.6.4.0) ...
    ```
    `dpkg` 명령어를 실행하여 패키지를 설치합니다. 

    <br>

    ```
    # cd /usr/local/pribit/wizard
    # ls -al
    drwxrwxr-x  5 pribit pribit  4096 Aug 12 06:27 .
    drwxrwxr-x  3 pribit pribit  4096 Aug 12 06:27 ..
    drwxrwxr-x  2 pribit pribit 20480 Aug 12 06:27 archives
    drwxrwxr-x 10 pribit pribit  4096 Aug 12 06:27 default-config
    drwxrwxr-x  4 pribit pribit  4096 Aug 12 06:27 src-compile
    -rwxrwxr-x  1 pribit pribit 42421 Jun 12 04:44 start-wizard.sh
    ```
    `deb` 패키지를 설치하면 `/usr/local/pribit/wizard/` 경로에 다음과 같은 파일이 생성됩니다. 

    <br><br>

2. **PCG 설치**
    - PCG 설치는 `start-wizard.sh` 스크립트를 실행하여 설치를 진행합니다.   

    - 설치 방식은 다음 두 가지가 있습니다.  
    - Offline 설치 방식 : `start-wizard.sh --off_line`
        -   인터넷 네트워크와 연결이 없는 Offline 으로 설치를 진행합니다. 
    - Online 설치 방식 : `start-wizard.sh`
        - 인터넷 네트워크와 연결된 Online 으로 설치를 진행합니다. 

    #### 설치 스크립트 start-wizard.sh 실행 
    ``` 
    # ./start-wizard.sh     
    ```
    `./start-wizard.sh` 명령어를 실행합니다. 
    >[!NOTE]  
    > 
    >인터넷(외부 네트워크)이 연결된 환경에서 실행해야 합니다.

    <br><br>

    #### PCG 가 사용할 in-memory Database(Redis)를 설치
    ```     
    ========================================================================================= 
    Enter in-memory DB new AUTH:  [패스워드 입력]
    Re-enter in-memory DB new AUTH: [패스워드 재입력]
    ``` 
    in-momory Database(Redis) 의 패스워드를 입력합니다. 
    
    _(Redis 패스워드 Pribit2560!)_
    
    <br><br>
    
    ```
    =========================================================================================
    remove unused package
    Reading package lists... Done
    Building dependency tree       
    Reading state information... Done
    Package 'tftpd-hpa' is not installed, so not removed

    ... 
    (중략)
    ...

    [2025-08-12T07:24:44,868] [main] INFO GatewayUtil -- createResourceFile path : /var/connect/gateway/system-integrity/inmemorydb.pgd
    =========================================================================================
    fnRedisSetting
    =========================================================================================
    Removed /etc/systemd/system/multi-user.target.wants/redis-server.service.
    Removed /etc/systemd/system/redis.service.
    Created symlink /etc/systemd/system/redis.service → /etc/systemd/system/redis-server.service.
    Created symlink /etc/systemd/system/multi-user.target.wants/redis-server.service → /etc/systemd/system/redis-server.service.
    =========================================================================================
    fnRedisSetting is complete
    =========================================================================================
    ```
    PCG 실행에 필요한 라이브러리 및 모듈을 설치합니다.
    
    *_([전체 설치 로그](Gateway_install.log))_*

    <br><br>

    ```
    ========================================================
            PacketGo Gateway Install was completed.
    OpenSSL has been updated. A system reboot is required.
    ========================================================
    ```
    설치가 완료되면 _'PacketGo Gateway Install was completed.'_ 라는 메시지가 나타나며 설치 과정이 완료됩니다.

    >[!WARNING]  
    > 
    >설치 이후 시스템 Reboot 필요 합니다.     
    ```
    # reboot
    ```

    <br><br>

3. **PCG Process 확인**
    - 설치가 정상적으로 완료되면 PCG 가 자동으로 실행되도록 되어 있습니다.
    - 모든 모듈이 정상적으로 기동되었는지 확인합니다. 

    - Process 확인
        - Web
            - gateway check
            - gateway rpc-server             

        ```
        # ps -ef | grep controller
        root       74231       1  0 Aug11 ?        00:04:20 /usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/web/controller-web-1.0.war
        root       74380       1  0 Aug11 ?        00:03:41 /usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/api/controller-api-1.0.jar
        root       74753       1  6 Aug11 ?        01:00:32 /usr/bin/java -server -Dpgct=connect-controller -Dpgct.home=/opt/connect/controller -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms2048m -Xmx3072m -jar /opt/connect/controller/rpc/controller-rpc-1.0.jar
        root       74990       1  0 Aug11 ?        00:08:18 /usr/bin/java -Djdk.lang.Process.launchMechanism=vfork -jar /opt/connect/controller/check/controller-check-1.0.jar
        ```

        - in-memory Database(Redis) 

        ```
        # ps -ef | grep redis
        redis     199607       1  0 16:25 ?        00:00:09 /usr/bin/redis-server 127.0.0.1:6379
        ```

    - Web Listen Port 확인 
        - TCP PORT 443: 
        - TCP PORT 5995: 
        - TCP PORT 5996: 
    ```
    # netstat -an | grep -E '443'\|'5995'\|'5996'
    tcp        0      0 0.0.0.0:5995            0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:5996            0.0.0.0:*               LISTEN     
    tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN
    ```

    <br><br>

4. **초기 설정**
    - PCG 가 정상적으로 기동되면 관리자 PC 에서 PCC Console 에 접속하여 Gateway를 등록합니다.  
    - 초기 설정([사용자 메뉴얼](/Documents/Connect%20Controller/UserManual.md)) 참고 

<br><br>

