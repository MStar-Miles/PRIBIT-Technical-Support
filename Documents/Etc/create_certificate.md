
### 1️⃣ 개인키 생성

```
openssl genrsa -out server.key 2048
```


### 2️⃣ SAN 설정 파일 생성  

```
ccat > san.cnf <<'EOF'
subjectAltName = @alt_names
[alt_names]
DNS.1 = pribit-portal-alb-1090845966.ap-northeast-2.elb.amazonaws.com
EOF
```

### 3️⃣ CSR 생성 (CN=ALB 도메인)  

```
oopenssl req -new -key server.key -out server.csr \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=PRIBIT/OU=IT/CN=pribit-portal-alb-1090845966.ap-northeast-2.elb.amazonaws.com"
```


### 4️⃣ 자가서명 인증서 생성 (유효기간 1년, SHA256, SAN 포함)  

```
oopenssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt \
  -sha256 -extfile san.cnf
```

### 💡 이렇게 하면 생성 결과는 다음처럼 됩니다.  

Certificate request self-signature ok
subject=C=KR, ST=Seoul, L=Seoul, O=PRIBIT, OU=IT, CN=pribit-portal-alb-1090845966.ap-northeast-2.elb.amazonaws.com
