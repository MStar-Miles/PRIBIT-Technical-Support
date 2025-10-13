#!/usr/bin/env bash
set -euo pipefail
TLS_DIR=/etc/nginx/tls
CRT=$TLS_DIR/nginx_ssl.crt
KEY=$TLS_DIR/nginx_ssl.key
PASS=$TLS_DIR/passwd

mkdir -p "$TLS_DIR"

# 패스워드/키/CSR/CRT (패스워드 파일 없으면 패스워드 보호 없이 생성)
if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  if [ -f "$PASS" ]; then
    PW=$(cat "$PASS")
    openssl genrsa -aes256 -passout pass:"$PW" -out "$KEY" 2048
    openssl req -new -key "$KEY" -out "$KEY.csr" -passin pass:"$PW" \
      -subj "/C=KR/ST=Seoul/L=Seoul/O=PRIBIT Technology/OU=PRIBIT Connect/CN=*.packetgo.com"
    openssl x509 -req -days 365 -in "$KEY.csr" -signkey "$KEY" -sha256 -out "$CRT" -passin pass:"$PW"
    rm -f "$KEY.csr"
  else
    openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
      -keyout "$KEY" -out "$CRT" \
      -subj "/C=KR/ST=Seoul/L=Seoul/O=PRIBIT Technology/OU=PRIBIT Connect/CN=*.packetgo.com"
  fi
fi
