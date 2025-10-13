#!/usr/bin/env bash
set -euo pipefail

# ====== 환경변수(필수) ======
: "${DB_HOST:=127.0.0.1}"         # host 네트워크 사용 시 127.0.0.1로 MariaDB 접근 가능
: "${DB_PORT:=3306}"
: "${DB_SCHEMA:=DB_PGZT}"         # 스크립트 기본값과 일치
: "${DB_USER:=pribit}"
: "${DB_PASSWORD:=Packetgo2560!}"
: "${ALLOWED_IP:=127.0.0.1}"      # 제품 설치 스크립트에서 입력받던 Allowed IP

APP_HOME=/opt/connect/controller
PROP_FILE="$APP_HOME/properties/authenticate.properties"

# ====== 인증서 준비 ======
/usr/local/bin/gen-selfsigned.sh

# ====== 프로퍼티가 없으면 생성 ======
if [ ! -f "$PROP_FILE" ]; then
  echo "[init] generating authenticate.properties (encrypted) ..."
  # util setup: user pw allowed_ip schema  ※ 원본 스크립트와 동일 순서
  java -jar "$APP_HOME/util/controller-util-1.0.jar" setup \
    "$DB_USER" "$DB_PASSWORD" "$ALLOWED_IP" "$DB_SCHEMA"
fi

# ====== DB 대기 후 legacy 수행 ======
echo "[wait] MariaDB ${DB_HOST}:${DB_PORT} ..."
for i in {1..120}; do
  (echo > /dev/tcp/${DB_HOST}/${DB_PORT}) >/dev/null 2>&1 && break || sleep 1
done
echo "[run] legacy migration ..."
java -jar "$APP_HOME/util/controller-util-1.0.jar" legacy  # 원본과 동일

# ====== 서비스 기동(Nginx/Web/API/RPC/Check) ======
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
