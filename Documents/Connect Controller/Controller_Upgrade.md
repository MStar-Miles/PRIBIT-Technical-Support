**TOC (Table Of Contents)**
<!-- TOC start  -->
- [./start-wizard.sh --update](#start-wizardsh---update)
- [./start-wizard.sh --update](#start-wizardsh---update-1)
- [ipsec cert, config create](#ipsec-cert-config-create)
      - [PCG Process 확인](#pcg-process-확인)
  - [troubleshooting](#troubleshooting)

<!-- TOC end -->

<br>

💡본 문서는 PRIBIT Connect Controller(이하 'PCC')의 버전 업그레이드 방법을 안내합니다. 

설치 버전 : `2.6.4.3` -> 업그레이드 버전 : `2.6.5.0`

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
# dpkg -i PRIBIT-Connect-Controller_[VERSION].deb
Selecting previously unselected package pribit-connect-controller-updater.
(Reading database ... 169493 files and directories currently installed.)
Preparing to unpack PRIBIT-Connect-Controller-Updater_2.6.5.0.deb ...
Unpacking pribit-connect-controller-updater (2.6.5.0) ...
Setting up pribit-connect-controller-updater (2.6.5.0) ...
```

<br>

`deb` 패키지를 설치하면 `/usr./local/pribit/connect/service/` 경로에 다음과 같은 파일이 생성됩니다. 

 ```
# cd /usr/local/pribit/connect/update/
# ls -al
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 api
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 check
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 rpc
-rwxrwxr-x 1 pribit pribit 6782 Sep  5 11:51 update.sh
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 util
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 web
drwxrwxr-x 2 pribit pribit 4096 Sep 24 15:16 web-console
```

<br>

PCC 업그레이드는 `update.sh` 스크립트를 실행하여 진행합니다.   

<br>

#### 업그레이드 스크립트 update.sh 실행

```
# ./update.sh  
```

<br>

#### PCC 버전 업그레이드 진행 

실행 로그 
```
stop connect-controller services ............
stop connect-controller-check services ............
stop connect-controller-web services ............
stop connect-controller-api services ............
start encryption init ............
[2025-09-24T15:32:40,832] [INFO] Start Patch......
[2025-09-24T15:32:51,715] [INFO] PCC DataBase Update Start......
[2025-09-24T15:32:52,906] [INFO] PCC DataBase Update End......
[2025-09-24T15:32:59,976] [INFO] PCC Legacy Table Setting Start......
[2025-09-24T15:33:00,235] [INFO] Already setting TB_EVDC and TB_EVDC_LEGACY SUCCESS
[2025-09-24T15:33:00,300] [INFO] Already setting TB_CORE_USER_ACT_LOG and TB_CORE_USER_ACT_LEGACY_LOG SUCCESS
[2025-09-24T15:33:00,301] [INFO] PCC Legacy Table Setting Completed......
start connect-controller-web services ............
start connect-controller-api services ............
start connect-controller services ............
start connect-controller-check services ............
=========================================================================================
PRIBIT Connect Controller Update was completed.
=========================================================================================
```

<br>

#### PCC Process 확인 
- 설치가 정상적으로 완료되면 PCC 가 자동으로 실행되도록 되어 있습니다.
- 모든 모듈이 정상적으로 기동되었는지 확인합니다. 
- 자세한 확인 방법은 [Controller_Installation의 3. PCC Process 확인](../Connect%20Controller/Controller_Installation.md#3-pcg-process-확인) 항목을 참고하세요.

<br><br>

## troubleshooting
