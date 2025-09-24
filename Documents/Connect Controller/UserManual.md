**TOC (Table Of Contents)**
<!-- TOC start  -->
- [사용자 관리](#사용자-관리)
  - [사용자 생성](#사용자-생성)
  - [비밀번호 강제 변경](#비밀번호-강제-변경)
  - [사용자 계정 동기화](#사용자-계정-동기화)
    - [RDBMS Database 동기화](#rdbms-database-동기화)
    - [Active Directory(LDAP) 동기화](#active-directoryldap-동기화)
  - [사용자 AD(LDAP) 인증](#사용자-adldap-인증)
    - [AD(LDAP) 인증 정책 생성](#adldap-인증-정책-생성)
    - [AD(LDAP) 인증을 위한 서버 정보 입력](#adldap-인증을-위한-서버-정보-입력)
- [PCA 배포 관리](#pca-배포-관리)
  - [PAC 관리 버전 등록](#pac-관리-버전-등록)
- [통신 어플리케이션](#통신-어플리케이션)
  - [통신 애플리케이션 등록](#통신-애플리케이션-등록)
    - [업무용 Web Server 에 접속하는 서비스를 msedge.exe 으로 실행하도록 Agent 에 등록](#업무용-web-server-에-접속하는-서비스를-msedgeexe-으로-실행하도록-agent-에-등록)
  - [Window File Server Explorer 등록](#window-file-server-explorer-등록)
      - [윈도우 탐색기 등록](#윈도우-탐색기-등록)
      - [System (윈도우 시스템 인증) 등록](#system-윈도우-시스템-인증-등록)

<!-- TOC end -->


## 사용자 관리  

<br>

### 사용자 생성 
- 최초 계정 생성 시 초기 비밀번호로 자동 설정됩니다. 
- 초기 비밀번호는 *`1111`* 입니다. 
- 사용자를 직접 생성 시에만 초기 비밀번호로 설정합니다. 

<br><br>

### 비밀번호 강제 변경 
- 계정 생성 후 비밀번호를 강제 변경 시, 기존 비밀번호를 요구하지 않습니다. 
- 비밀번호 강제 변경
  - = (비밀번호 초기화 + 비밀번호 변경)  

<br><br>

### 사용자 계정 동기화

OBJECT > 사용자 계정 동기화 
![UserAccountSyncList](./img/useracct_synclist.png)

<br>

#### RDBMS Database 동기화 

동기화 방법 선택 화면에서 `데이터베이스 연결` 을 선택합니다. 

![UserAccountSyncTypeDbms](./img/useracct_sync_type.png)

- [x] 데이터베이스 연결  

<br>

데이터베이스 설정 

![UserAccountSyncDbmsConf1](./img/useracct_sync_dbms_conf1.png)

- 데이터베이스 종류 
  - 연결 가능한 데이터베이스 종류는 `Orcle`, `MySQL(MariaDB)`, `PostgreSQL`, `SqlServer(Microsoft SQL)` 를 지원합니다. 
  - ex) 
    - [x] *`MySQL(MariaDB)`*  
- 데이터베이스 IP 
  - 연결할 데이터베이스의 IP 주소를 입력합니다. 
  - ex) *`10.0.30.156`*  
- 데이터베이스 포트 
  - 연결할 데이터베이스의 포트 정보를 입력합니다. 
  - *Oracle: 1521, MySQL(MariaDB): 3306, PostreSQL: 5432, SqlServer(Microsoft SQL): 1443*  
  - ex) *`3306`*  
- 데이터베이스 사용자 아이디 
  - 연결할 데이터베이스의 계정 정보를 입력합니다. 
  - ex) *`pribit`* 
- 데이터베이스 사용자 비밀번호 
  - 연결할 데이터베이스의 계정 비밀번호를 입력합니다. 
  - ex) *`Pa********60!`*
- 데이터베이스명 or SID
  - 연결할 데이터베이스명 또는 SID(Oracle) 값을 입력합니다. 
  - ex) *`DB_PGZT`*  

<br>

사용자 테이블 설정 

![UserAccountSyncDbmsConf2](./img/useracct_sync_dbms_conf2.png)

사용자 동기화 방법 

※ 동기화 시 고객사 데이터베이스의 변경된 정보로 PCC의 사용자 정보를 업데이트 또는 삭제합니다.  

- [x] 사용자 정보 업데이트 처리 
- [x] 사용자 정보 삭제 처리 

사용자 동기화 테이블 및 필드 정보 

- 사용자 테이블명 or 뷰 
  - 사용자 계정의 테이블을 입력합니다. 
  - ex) *`USERS`*  
- 로그인 아이디 필드명
  - 사용자 계정 테이블의 Login ID 컬럼 명을 입력합니다. 
  - ex) *`USER_ID`* 
- 계정명 필드명
  - 사용자 계정 테이블의 사용자 이름 컬럼 명을 입력합니다. 
  - ex) *`USER_NAME`* 
- 이메일 주소 필드명 
  - 사용자 계정 테이블의 사용자 이메일 컬럼 명을 입력합니다. 
  - ex) *`EMAIL_ADDR`* 
- 사용자 휴대전화 번호 필드명 
  - 사용자 계정 테이블의 사용자 휴대전화 번호 컬럼 명을 입력합니다. 
  - ex) *`USER_PHONE`* 
- 사용자 그룹 아이디 필드명 
  - ex) (blank) 
- 사용자 비밀번호 필드명 
  - ex) (blank) 
- 사용자 비밀번호 솔트 필드명 
  - ex) (blank) 
- 비밀번호 변경 일자 설정 
  - 동기화 시 비밀번호 변경 일자를 설정하는 방법을 *`사용 안함`*, *`동기화 일시로 자동 업데이트`* 로 설정합니다.  
  - ex) 
    - [x] *`사용 안함`*
- 초기 상태값 
  - 동기화 시 사용자의 상태를 *`사용 가능`*, *`사용 불가`*, *`사용 대기`* 로 설정합니다.  
  - ex)
    - [x] *`사용 가능`* 

<br> 

> [!NOTE] 사용자의 "사용 대기" 상태 
> 사용자의 `사용 대기` 상태는 동기화 시에만 지정 할 수 있는 사용자의 상태입니다. 
> 사용자는 `사용 대기` 상태가 되면, 관리자가 반드시 직접 `사용 가능` 상태로 전환 해주어야 합니다. 

<br>

사용자 그룹 테이블 설정  

(본 가이드에서는 사용자 그룹 동기화는 진행하지 않습니다.)

![UserAccountSyncDbmsConf3](./img/useracct_sync_dbms_conf3.png)

사용자 그룹 동기화 방법  

- [ ] 사용자 그룹 정보 등록 처리 
- [ ] 사용자 그룹 정보 업데이트 처리 
- [ ] 사용자 그룹 정보 삭제 처리 

사용자 그룹 동기화 테이블 및 필드 정보 

- 사용자 그룹 테이블명 or 뷰 
  - ex) (blank) 
- 사용자 그룹 아이디 필드명 
  - ex) (blank) 
- 사용자 그룹명 필드명 
  - ex) (blank) 
- 사용자 그룹 정렬 필드명 
  - ex) (blank) 
- 사용자 그룹 참조 ID 필드명 
  - ex) (blank) 
  
사용자 그룹 동기화 ROOT 정보 

- 고객사 ROOT 그룹 REference ID 
  - ex) (blank)
- ROOT 그룹으로 사용할 사용자 그룹 ID (선택) 
  - 최상위 그룹의 위치를 지정할 수 있습니다. 
    - ex) (blank)  

<br>

동기화 실행 

![UserAccountSyncDbmsConf4](./img/useracct_sync_dbms_conf4.png)

동기화 설정을 완료 후 실제 계정 동기화 수행을 진행하려면 `동기화 실행` 버튼을 눌러 진행해야 합니다. 

<br>

#### Active Directory(LDAP) 동기화 

동기화 방법 선택 화면에서 `LDAP 서버 연결` 을 선택합니다. 
AD를 기본으로 설정했다면 아래 안내되는 설정과 크게 다르지 않습니다.  
기본적으로는 예시에 설정된 값으로 적용을 합니다. (AD 서버 IP, 접속 계정, 비밀번호는 제외)  

![UserAccountSyncTypeLdap](./img/useracct_sync_type.png)

- [x] LDAP 서버 연결  

<br>

LDAP 서버 동기화 설정 

![UserAccountSyncLdapServerConf1](./img/useracct_sync_ldap_conf1.png)  

- LDAP 종류 
  - [x] Active Directory 
- LDAP 서버 IP  
  - ex) *`10.0.30.158`*  
- LDAP 서버 접속 포트  
  - ex) *`389`*  
- over SSL
  - [x] 사용 안함  
- LDAP 사용자 아이디  
  - ex) *`administrator@pribit.com`*  
  - 사용자 계정은 `@도메인` 으로 입력해주어야 합니다. 
- LDAP 사용자 비밀번호 
  - ex) *`Pri***60!`*  
- 사용자 Distinguished Name(OU)  
  - ex) *`OU=TechCorp,DC=pribit,DC=com`*  
- 사용자 그룹 조직구성단위 Distinguished Name(OU)  
  - ex) (blank)  
- 인증 메커니즘 
  - [x] simple  
- 1회 허용 레코드 수 
  - ex) *`50`*  

<br>

사용자 동기화 Canonical Name(CN) 정보  

![UserAccountSyncLdapServerConf2](./img/useracct_sync_ldap_conf2.png)  

- 사용자 정보 등록 처리 
  - [x] 사용자 정보 업데이트 처리  
  - [x] 사용자 정보 삭제 처리  
- 사용자 Distinguished Name(DN)  
  - AD 에서 기본적으로 생성하게되면 *`distinguishedName`* 로 생성됩니다.  
  - ex) *`distinguishedName`*  
- 사용자 objectClass  
  - AD 에서 기본적으로 생성하게되면 *`user`* 으로 설정됩니다.  
  - ex) *`user`*  
- 로그인 아이디 속성  
  - AD 에서 기본적으로 생성하게되면 *`sAMAccountName`* 로 생성됩니다.  
  - ex) *`sAMAccountName`*  
- 계정명 속성  
  - ex) (blank)  
- 이메일 주소 속성  
  - AD 에서 기본적으로 생성하게되면 *`userPrincipalName`* 로 생성됩니다.  
  - ex) *`userPrincipalName`*  
- 사용자 휴대전화 번호 속성  
  - ex) (blank)  
- 사용자 그룹 아이디 속성  
  - ex) (blank)  
- 사용자 비밀번호 속성  
  - ex) (blank)  
- 비밀번호 변경 일자 설정 
  - [x] 사용 안함  
- 초기 상태값
  - [x] 사용 가능 

<br>

> **비밀번호 변경 일자 설정:** `사용 안함` / `동기화 일시로 자동 업데이트`  
> PCC DB에 계정 동기화 시 계정의 비밀번호 업데이트 일시를 동기화 일시로 자동 업데이트합니다.   

<br>

> [!NOTE] 초기 상태값: 사용 가능 / 사용 불가 / 사용 대기    
> PCC DB에 계정 동기화 시 계정의 초기 상태값을 `사용 가능` / `사용 불가` / `사용 대기` 중 하나로 설정합니다.   
> `사용 가능` : 정상 사용자  
> `사용 불가` : 잠김 사용자  
> `사용 대기` : 대기 사용자  

<br>

사용자 그룹 조직구성단위(OU) 정보 
![UserAccountSyncLdapServerConf3](./img/useracct_sync_ldap_conf3.png)  

사용자 그룹 동기화 방법
- [x] 사용자 그룹 정보 등록 처리  
- [x] 사용자 그룹 정보 업데이트 처리  
- [x] 사용자 그룹 정보 삭제 처리  

사용자 그룹 조직구성단위(OU) 정보  
- 사용자 그룹 Distinguished Name(DN)  
  - AD 에서 기본적으로 생성하게되면 *`distinguishedName`* 로 생성됩니다.  
  - ex) *`distinguishedName`*  
- 사용자 그룹 objectClass  
  - AD 에서 기본적으로 생성하게되면 *`organizationalUnit`* 로 생성됩니다.  
  - ex) *`organizationalUnit`*  
- 사용자 그룹 아이디 속성  
  - ex) (blank)  
- 사용자 그룹명 속성  
  - ex) (blank)  
- 사용자 그룹 정렬 속성  
  - ex) *`ou`*
- 사용자 그룹 참조 ID 속성  
  - ex) (blank)  

사용자 그룹 동기화 ROOT 정보
- 고객사 ROOT 그룹 Reference ID  
  - ex) (blank)  
- ROOT 그룹으로 사용할 사용자 그룹 ID  
  - 최상위 그룹의 위치를 지정합니다. 
  - ex) *`ROOT`*   

<br>

동기화 실행 
![UserAccountSyncRun](./img/useracct_sync_run.png)  

동기화 설정을 완료 후 실제 계정 동기화 수행을 진행하려면 `동기화 실행` 버튼을 눌러 진행해야 합니다. 

<br>

사용자 동기화 완료 
![UserAccountSyncComplete](./img/useracct_sync_run_complete.png)  

<br>

사용자 그룹 동기화 완료  
![UserGroupAccountSyncRun](./img/usergroupacct_sync_run_complete.png)  

<br>

### 사용자 AD(LDAP) 인증 

> [!NOTE] 사용자 AD 인증 
> 사용자 로그인 처리를 AD(LDAP) 으로 수행(정책 지정)할 경우, 반드시 동기화가 먼저 진행되어야 한다.  
> 즉, 사용자 계정이 PCC에 이미 존재해야 인증을 수행 할 수 있다. 

<br>

#### AD(LDAP) 인증 정책 생성  
POLICY > 단말 상태 확인 및 행위 제어 
![PolicyList](./img/policy_list.png)  

AD(LDAP) 인증 수행을 위해서는 POLICY 에서 단말 인증 수행에 대한 정책을 생성해주고 적용해야 합니다. 
![Policy LDAP Authentication](./img/create_policy_ldap_auth.png)

적용한 플랫폼(다중 선택 가능)  
![Policy LDAP Authentication1](./img/create_policy_ldap_auth1.png)  
- ex) 
  - [x] Microsoft Windows 

`LDAP` 으로 검색합니다. 
![Policy LDAP Authentication2](./img/create_policy_ldap_auth2.png)
`LDAP 인증 수행` 을 선택합니다. 

> [!Note] LDAP 인증 시 제약 사항  
> Ldap 인증 수행 정책 사용 시, 아래의 기능 및 정책 사용이 제한됩니다.   
> - 기능: 사용자 비밀번호 초기화, 사용자 비밀번호 강제 변경, 간편 인증 사용  
> - 정책: 비밀번호 마지막 변경 기간 초과 시 비밀번호 변경  

적용 대상  
![Policy LDAP Authentication3](./img/create_policy_ldap_auth3.png)  
- ex) 
  - [x] 모든 플로우 제어 영역에 적용  
  - [x] 모든 사용자에 적용  

상태 
- ex) 
  - [x] 사용 가능 

<br>

#### AD(LDAP) 인증을 위한 서버 정보 입력

단말 상태 확인 및 행위 제어 목록에서 상세 조건의 LDAP 인증 수행 설정정보를 추가로 입력해야 합니다. 

![Policy LDAP Authentication3](create_policy_ldap_auth4.png)  


🔄 모양의 아이콘을 눌러 인증정보를 추가합니다. 
![Policy LDAP Authentication3](create_policy_ldap_auth5.png)  
- LDAP 서버 IP 
  - ex) *`10.0.30.158`*  
- LDAP 서버 접속 포트
  - ex) *`389`*  
- over SSL 
  - ex) 
    - [x] 사용 안함  
- 인증 메커니즘  
  - ex)  
    - [x] sample  
- kdc  
  - ex) (blank)  
- realm  
  - ex) (blank)  

<br> 

*** 

<br><br>

## PCA 배포 관리 
### PAC 관리 버전 등록 
에이전트를 사용하기 위해서는 PCC에 에이전트 배포 관리에 등록하여야 사용할 수 있습니다. 

SYSTEM > 에이전트 배포 관리

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






