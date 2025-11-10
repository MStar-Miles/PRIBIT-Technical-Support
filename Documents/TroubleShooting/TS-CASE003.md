# VPN 클라이언트 OpenSSL 오류 해결 가이드

## 1. 문제 원인 분석

### 고객사 환경 오류 특징
- OpenSSL 난수 생성기(RAND_bytes) 실패
- 그룹 정책으로 보안 설정 제한
- CSP 레지스트리는 활성화 상태

### 예상되는 주요 원인
1. **FIPS 140-2 준수 모드 활성화**
2. **암호화 공급자(CSP) 정책 제한**
3. **TLS/SSL 암호화 스위트 제한**
4. **엔트로피 소스 접근 제한**

## 2. 레지스트리 백업 (필수 수행)

### 백업 생성
```cmd
# 전체 암호화 관련 레지스트리 백업
reg export "HKLM\SYSTEM\CurrentControlSet\Control\LSA\FipsAlgorithmPolicy" "%TEMP%\fips_backup.reg"
reg export "HKLM\SOFTWARE\Microsoft\Cryptography" "%TEMP%\crypto_backup.reg"
reg export "HKLM\SYSTEM\CurrentControlSet\Control\LSA" "%TEMP%\lsa_backup.reg"

# 백업 확인
dir "%TEMP%\*_backup.reg"
```

### 백업 복원 방법
```cmd
# 문제 발생 시 원복
reg import "%TEMP%\fips_backup.reg"
reg import "%TEMP%\crypto_backup.reg" 
reg import "%TEMP%\lsa_backup.reg"

# 시스템 재부팅 필요
shutdown /r /t 30
```

## 3. 재현 방법들

### 방법 1: FIPS 140-2 모드 활성화 (가장 유력)
```cmd
# 재현 - FIPS 모드 활성화
reg add "HKLM\SYSTEM\CurrentControlSet\Control\LSA\FipsAlgorithmPolicy" /v "Enabled" /t REG_DWORD /d 1 /f

# 재부팅 후 테스트
shutdown /r /t 60

# 원복 - FIPS 모드 비활성화
reg add "HKLM\SYSTEM\CurrentControlSet\Control\LSA\FipsAlgorithmPolicy" /v "Enabled" /t REG_DWORD /d 0 /f
shutdown /r /t 60
```

### 방법 2: Strong Cryptographic Provider 비활성화
```cmd
# 재현 (이미 확인된 방법)
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Strong Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "" /f

# 원복
reg delete "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Strong Cryptographic Provider v1.0" /v "Image Path" /f
# 또는 원래 값으로 복원
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Strong Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "rsaenh.dll" /f
```

### 방법 3: Enhanced Cryptographic Provider 비활성화
```cmd
# 재현
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Enhanced Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "" /f

# 원복
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Enhanced Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "rsaenh.dll" /f
```

### 방법 4: Base Cryptographic Provider 비활성화
```cmd
# 재현
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Base Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "" /f

# 원복  
reg add "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Base Cryptographic Provider v1.0" /v "Image Path" /t REG_SZ /d "rsaenh.dll" /f
```

### 방법 5: TLS 1.2 이하 버전 비활성화
```cmd
# 재현 - TLS 1.0 비활성화
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "Enabled" /t REG_DWORD /d 0 /f

# 원복
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "Enabled" /t REG_DWORD /d 1 /f  
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "Enabled" /t REG_DWORD /d 1 /f
```

## 4. 고객사 환경 확인 방법

### FIPS 모드 확인
```cmd
# 레지스트리로 확인
reg query "HKLM\SYSTEM\CurrentControlSet\Control\LSA\FipsAlgorithmPolicy" /v "Enabled"

# PowerShell로 확인  
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\LSA\FipsAlgorithmPolicy" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
```

### CSP 상태 확인
```cmd
# 주요 CSP 확인
reg query "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Strong Cryptographic Provider v1.0" /v "Image Path"
reg query "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Enhanced Cryptographic Provider v1.0" /v "Image Path"
reg query "HKLM\SOFTWARE\Microsoft\Cryptography\Defaults\Provider\Microsoft Base Cryptographic Provider v1.0" /v "Image Path"
```

### 그룹 정책 확인
```cmd
# 현재 적용된 그룹 정책 확인
gpresult /r
gpresult /h gp_report.html

# 보안 정책 확인 (고객사에서 제한됨)
secpol.msc
```

## 5. 해결 방안

### 임시 해결책
1. **FIPS 모드가 활성화된 경우**: OpenSSL을 FIPS 호환 모드로 컴파일하거나 FIPS 인증된 라이브러리 사용
2. **CSP 제한이 있는 경우**: Windows CNG(Cryptography API: Next Generation) 기반으로 전환

### 근본적 해결책
1. **VPN 클라이언트 업데이트**: FIPS 140-2 준수 OpenSSL 버전 사용
2. **정책 예외 요청**: IT 보안팀에 VPN 클라이언트에 대한 암호화 정책 예외 요청
3. **대체 암호화 라이브러리**: Windows 네이티브 Schannel 사용

## 6. 안전한 테스트 순서

1. **백업 생성** (필수)
2. **FIPS 모드 확인 및 테스트** (가장 유력한 원인)
3. **CSP 비활성화 테스트** (이미 확인된 방법)
4. **TLS 정책 테스트**
5. **각 단계별 원복 확인**
6. **최종 시스템 재부팅**

## 7. 주의사항

- 모든 레지스트리 수정 전 반드시 백업 생성
- 테스트는 중요하지 않은 시스템에서 우선 수행
- FIPS 모드 변경 시 시스템 재부팅 필수
- 원복 시에도 재부팅 필요
- 그룹 정책이 적용된 환경에서는 정책이 다시 적용될 수 있음