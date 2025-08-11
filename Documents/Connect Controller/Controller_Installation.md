# PRIBIT Connect Controller Installation

💡이 문서는 PRIBIT Connect Controller 설치(step-by-step)에 대한 가이드를 제공합니다.  

설치 버전 : `2.6.4.3`


## Prerequisites

- 설치 환경([Prerequisites](./Prerequisites.md)) 준비
- 시스템 구성([System Architecture](/Documents/Architecture/architecture.md)) 확인 

## Installation Steps

1. **PRIBIT Controller Package 압축 해제** 
    - 설치를 진행 할 계정을 root 로 변경해줍니다. 
    - 설치 시작 위치에 패키지 파일을 준비해 놓습니다. 

    <br><br>

    ```
    dpkg -i PRIBIT-Connect-Controller-Focal_[VERSION].deb

    Selecting previously unselected package pribit-connect-controller.
    (Reading database ... 145175 files and directories currently installed.)
    Preparing to unpack PRIBIT-Connect-Controller-Focal_[VERSION].deb ...
    Unpacking pribit-connect-controller ([VERSION]) ...
    Setting up pribit-connect-controller ([VERSION]) ...
    ```
    `dpkg` 명령어를 실행하여 패키지를 설치합니다. 

    <br><br>

    ```
    cd /usr/local/pribit/connect/services
    ls -al
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

2. **Controller 설치**
    - PRIBIT Connect Controller 설치 방식에는 `install_offline.sh`, `install_online.sh` 두 가지가 있다. 
    - `install_offline.sh` 설치 

    <br><br>

    ``` 
    ./install_offline.sh 
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


3. **Controller DB 설치**
    - Controller 가 사용할 Database를 설치합니다. 
    
    

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

4. **Connect to Network**
    - Use an Ethernet cable or Wi-Fi to connect the controller to your network.

5. **Initial Configuration**
    - Power on the controller.
    - Follow the on-screen instructions or refer to the user manual for initial setup.

## Troubleshooting

- If the controller does not power on, check the power connections.
- For network issues, verify cable connections and network settings.

## Support

For further assistance, contact technical support.
