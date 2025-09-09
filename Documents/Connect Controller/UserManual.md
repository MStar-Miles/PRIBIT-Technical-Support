**TOC (Table Of Contents)**
<!-- TOC start  -->
- [PCA 배포 관리](#pca-배포-관리)
  - [PAC 관리 버전 등록](#pac-관리-버전-등록)

<!-- TOC end -->

## PCA 배포 관리 
### PAC 관리 버전 등록 
에이전트를 사용하기 위해서는 PCC에 에이전트 배포 관리에 등록하여야 사용할 수 있습니다. 

![Agent Registration Management](./img/agent_management.png)  

등록버튼을 눌러 에이전트 등록을 진행합니다. 

![Agent Registration](./img/regist_agent.png)  
- 플랫폼 : Agent 의 플랫폼의 종류를 선택합니다. (단일 선택)
  - [ ] Microsoft Windows 
  - [ ] Apple MacOS 
  - [ ] Google Android 
  - [ ] Google Android Tablet 
  - [ ] Apple iOS 
  - [ ] Apple iPadOS 
  - ex) *Microsoft windows* 
- 종류 : 플랫폼에 설치될 형태를 선택합니다. (단일 선택) 
  - [ ] 애플리케이션 
  - [ ] 모듈 
  - ex) *애플리케이션* 
- 버전 : 등록할 PCA 의 버전을 입력합니다. 
  - ex) *2.6.4.18* 
- [ ] 필수 업데이트 : 필수로 업데이트를 진행합니다. 
- [ ] 업데이트 알림 : 업데이트 시 알림을 받습니다. 
- 릴리즈 노트 : 배포 할 에이전트 버전에 대한 릴리즈 노트입니다. (필수입력)
  - ex) *1. Ubuntu 24.04.02 지원<br>2. Gateway 오프라인 설치 지원<br>...<br>17. 그 외 UI/UX 개선 버전* 
- 배포 URL : 에이전트를 다운받거나 설치 할 수 있는 URL을 입력합니다. (필수입력)
  - ex) *https://pribit.packetgo.com/agent/distribution* 

에이전트 등록을 완료하면 "대기" 상태로 생성됩니다. 

![Registered Agent](./img/registered_agent.png)  

"상태 변경"을 눌러 Agent 상태를 "배포"로 변경합니다. 

![Agent Distrubution Management](./img/agent_distribution_management.png) 

- 배포 : 등록했던 Agent 를 배포(사용)로 변경합니다. 
- 대기 : 등록했던 Agent 를 대기 상태로 변경합니다. 
- 테스트 : 등록했던 Agent 를 테스트 상태로 변경합니다.

<br><br>

