**TOC (Table Of Contents)**
<!-- TOC start  -->
- [PCA 배포 관리](#pca-배포-관리)
  - [PAC 관리 버전 등록](#pac-관리-버전-등록)
    - [SYSTEM \> 에이전트 배포 관리](#system--에이전트-배포-관리)
- [통신 어플리케이션](#통신-어플리케이션)
  - [통신 애플리케이션 등록](#통신-애플리케이션-등록)
    - [업무용 Web Server 에 접속하는 서비스를 msedge.exe 으로 실행하도록 Agent 에 등록](#업무용-web-server-에-접속하는-서비스를-msedgeexe-으로-실행하도록-agent-에-등록)
  - [Window File Server Explorer 등록](#window-file-server-explorer-등록)
      - [윈도우 탐색기 등록](#윈도우-탐색기-등록)
      - [System (윈도우 시스템 인증) 등록](#system-윈도우-시스템-인증-등록)

<!-- TOC end -->

## PCA 배포 관리 
### PAC 관리 버전 등록 
에이전트를 사용하기 위해서는 PCC에 에이전트 배포 관리에 등록하여야 사용할 수 있습니다. 

#### SYSTEM > 에이전트 배포 관리

![Agent Registration Management](./img/agent_management.png)  

등록버튼을 눌러 에이전트 등록을 진행합니다. 

![Agent Registration](./img/regist_agent.png)  
- 플랫폼 : Agent 의 플랫폼의 종류를 선택합니다. (단일 선택)
  - ex) 
  - [x] Microsoft Windows 

- 종류 : 플랫폼에 설치될 형태를 선택합니다. (단일 선택) 
  - ex)  
  - [x] 애플리케이션 

- 버전 : 등록할 PCA 의 버전을 입력합니다. 
  - ex) *`2.6.4.18`* 

- [ ] 필수 업데이트 : 필수로 업데이트를 진행합니다. 

- [ ] 업데이트 알림 : 업데이트 시 알림을 받습니다. 
  
- 릴리즈 노트 : 배포 할 에이전트 버전에 대한 릴리즈 노트입니다. (필수입력)
  - ex) *1. Ubuntu 24.04.02 지원<br>2. Gateway 오프라인 설치 지원<br>...<br>17. 그 외 UI/UX 개선 버전* 

- 배포 URL : 에이전트를 다운받거나 설치 할 수 있는 URL을 입력합니다. (필수입력)
  - ex) *`https://pribit.packetgo.com/agent/distribution`* 

에이전트 등록을 완료하면 `대기` 상태로 생성됩니다. 

![Registered Agent](./img/registered_agent.png)  

`상태 변경`을 눌러 Agent 상태를 `배포`로 변경합니다. 

![Agent Distrubution Management](./img/agent_distribution_management.png) 

- 배포 : 등록했던 Agent 를 배포(사용)로 변경합니다. 
- 대기 : 등록했던 Agent 를 대기 상태로 변경합니다. 
- 테스트 : 등록했던 Agent 를 테스트 상태로 변경합니다.

<br><br>


## 통신 어플리케이션  

### 통신 애플리케이션 등록  
애플리케이션 플로우 정책에 적용할 통신(용) 애플리케이션을 생성하고 관리합니다. 

#### 업무용 Web Server 에 접속하는 서비스를 msedge.exe 으로 실행하도록 Agent 에 등록 

Agent 에서 서비스 목록에 표시하기 위해서는 애플리케이션 플로우에서 `별칭` 으로 서비스를 등록해야 합니다. 
그리고, `별칭` 에 서비스로 등록하기 위해서는 통신 애플리케이션이 생성되어 있어야 합니다.  

OBJECT > 통신 애플리케이션 
![Application For Access](./img/community_application_list.png)

애플리케이션을 등록하기 위해 `애플리케이션 등록` 버튼을 눌러 등록 절차를 시작합니다. 

애플리케이션 등록 

![Application For Access - Add Comm App Info](./img/community_application_add_info.png)  

애플리케이션 정보를 입력합니다.  

- 플랫폼 : *플랫폼 종류를 선택합니다.*
  - ex) 
  - [x] Microsoft Windows 

- 애플리케이션 명 : *통신 애플리케이션의 이름 입니다.식별을 위한 명칭으로 임의지정이 가능합니다. * 
  - ex) `윈도우 엣지` 

- 프로세스 명 : *통신 애플리케이션의 프로세스명 입니다.실제 단말의 프로세스명을 입력해야 정상적인 애플리케이션 통신 제어가 가능합니다.*  
  - ex) `msedge.exe`  

<br>

애플리케이션 유효성 검사 정보 (`다중 선택 가능`)  
![Application For Access - Add Comm App Integrity](./img/community_application_add_integrity.png)

- 코드 사인값 비교(일치) : 
  - ex) `선택 안함`

- 코드 사인값 비교(포함) : 
  - ex) `선택 안함`  

- 실행 파일 해쉬값 비교 : 
  - ex) `선택 안함` 

- 실행 위치 비교 : *실행 될 애플리케이션의 위치를 입력합니다. 해당 위치에 실행 파일이 없을 경우 정상 동작하지 않을 수 있습니다.*  
  - ex) C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe

<br>

OBJECT > 통신 애플리케이션  
![Application For Access - Add Comm App Complete](./img/community_application_add_commplete.png)

생성된 정보를 확인 할 수 있습니다. 

<br>

FLOW > 애플리케이션 플로우 > 통신 애플리케이션   
![Apply Community Application](./img/apply_comm_app.png)

`애플리케이션 정보 변경` 으로 통신 애플리케이션을 등록해줍니다. 

![Apply Community Application - Add](./img/apply_comm_app_add.png)

`접속 가능한 애플리케이션 선택` 목록에서 통신 애플리케이션 에서 생성한 `윈도우 엣지(msedge.exe)` 를 추가합니다. 

<br>  

FLOW > 애플리케이션 플로우 > 별칭 

![Apply Nickname](./img/apply_nickname_list.png)  

`별칭 등록` 으로 별칭을 등록해줍니다. 

![Apply Nickname - Info](./img/apply_nickname_add.png)  

- 별칭 : 
  - ex) 업무 서비스(Naver.com) 
- 접속 네트워크 정보 : 
  - ex) https://www.naver.com 
- 통신 애플리케이션 : 
  - ex) 
  - [x] 윈도우 엣지  

<br>  

에이전트에 표시 될 애플리케이션 종류  
![Apply Nickname - Add Type](./img/apply_nickname_add_type.png)

- ex) *서비스에 맞는 종류를 선택합니다.*
- [x] 웹 

<br> 

등록한 별칭을 확인합니다. 
![Apply Nickname - Add Complete](./img/apply_nickname_add_commplete.png) 

<br>

에이전트에서 접속하여 서비스 목록을 확인하고 해당 서비스에 접속합니다.  

![Applied Nickname for agent](./img/apply_nickname_for_agent.png)

<br>

접속된 업무 서비스(www.naver.com)  

![Access Service and Applied Nickname for agent](./img/access_service_and_apply_nickname_for_agent.png)

<br><br>

### Window File Server Explorer 등록 
윈도우 탐색기를 이용하여 파일 서버에 접속하는 서비스를 등록할 때, 해당 절차로 등록을 수행해야 합니다.  

Object > 통신 애플리케이션에서 애플리케이션 등록 시 아래 두 가지를 모두 등록해주어야 합니다. 

- 윈도우 탐색기 (explorer.exe)
- System (윈도우 시스템 인증)

먼저 윈도우 탐색기를 등록해줍니다. 

[통신 애플리케이션 등록](#통신-애플리케이션-등록) 과정과 동일하게 아래 정보로 통신 애플리케이션을 등록합니다. 

##### 윈도우 탐색기 등록 

애플리케이션 정보 선택 및 입력
- 플랫폼 : 
  - [x] Microsoft Windows 
- 애플리케이션 명 : *어플리케이션 명은 변경 가능합니다.*
  - Windows File Explorer
- 프로세스 명(실행을 감시할 파일명일자) : 
  - explorer.exe

애플리케이션 유효성 검사 정보 (다중 선택 가능)  

- 코드 사인값 비교(일치) : 
  - `선택 안함`  
- 코드 사인값 비교(포함) : 
  - `선택 안함`  
- 실행 파일 해쉬값 비교 : 
  - `선택 안함`  
- 실행 위치 비교 : 
  - `C:\Windows\explorer.exe` 


##### System (윈도우 시스템 인증) 등록 

애플리케이션 정보 선택 및 입력
- 플랫폼 : 
  - [x] Microsoft Windows 
- 애플리케이션 명 : *어플리케이션 명은 변경 가능합니다.*
  - `Windows File Server`
- 프로세스 명(실행을 감시할 파일명일자) : 
  - `System`  

애플리케이션 유효성 검사 정보 (다중 선택 가능)  

- 코드 사인값 비교(일치) : 
  - `선택 안함`  
- 코드 사인값 비교(포함) : 
  - `선택 안함`  
- 실행 파일 해쉬값 비교 : 
  - `선택 안함`  
- 실행 위치 비교 : 
  - `C:\Windows\System32\config\SYSTEM`   

<br> 

![Communication Application for File Explorer](./img/communication_app_for_file_explorer.png)

프로세스 `System`, `explorer.exe` 두 설정이 생성되어야 합니다. 

이제, 생성된 설정들을 애플리케이션 플로우의 설정에 적용시킵니다. 

<br>

FLOW > 애플리케이션 플로우  

별칭으로 등록하려면 통신 애플리케이션을 먼저 등록해주어야 별칭으로 등록 가능합니다.  
통신 애플리케이션 > 애플리케이션 정보 변경 클릭해줍니다.  

![Add Communication Application File Explorer And Windows Auth](./img/add_comm_app_for_file_explorer_and_windows_auth.png)  
접속 가능한 애플리케이션 선택 목록에서 앞서 만든 통신 애플리케이션들(Windows File Explorer, Windows File Server)들을 등록해줍니다.  

<br> 

다시, 별칭 탭으로 넘어가서 별칭 등록합니다.  

![Add Nickname Communication Application for Windows File Server Explorer](./img/add_nickname_comm_app_for_windows_file_server_explorer.png)

- 별칭 : *에이전트 앱에서 서비스로 노출 될 서비스명입니다.*  
  - `Windows File Server`   

- 접속 네트워크 정보 : *접속할 윈도우 파일 서버 주소를 입력합니다.*
  - `\\192.168.0.125`   

- 에이전트에 표실될 애플리케이션 종류 : 
  - [x] 일반  

<br>

에이전트에서 아래와 같이 접속하여 Windows File Server 에 접속합니다.  

![Access Windows File Server - Windows Auth](./img/access_windows_file_server_winauth.png)

<br><br> 






