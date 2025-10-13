# controller/Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
# 타임존은 컨테이너 내부 로컬시간 영향만 — 필요 시 유지
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless curl ca-certificates tzdata \
    nginx-extras openssl procps supervisor dumb-init \
 && rm -rf /var/lib/apt/lists/*

# 디렉토리
RUN mkdir -p /opt/connect/controller/{rpc,api,web,check,util,properties} \
    /opt/connect/logs /etc/nginx/tls

# 아티팩트 복사
COPY artifacts/rpc/controller-rpc-1.0.jar /opt/connect/controller/rpc/
COPY artifacts/api/controller-api-1.0.jar /opt/connect/controller/api/
COPY artifacts/web/controller-web-1.0.war /opt/connect/controller/web/
COPY artifacts/check/controller-check-1.0.jar /opt/connect/controller/check/
COPY artifacts/util/controller-util-1.0.jar /opt/connect/controller/util/

# Nginx 설정 & 기동 스크립트/슈퍼바이저
COPY nginx.conf /etc/nginx/nginx.conf
COPY gen-selfsigned.sh /usr/local/bin/gen-selfsigned.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 700 /usr/local/bin/entrypoint.sh /usr/local/bin/gen-selfsigned.sh \
    && chmod 644 /etc/nginx/nginx.conf

# 포트 (host 네트워크를 쓸 예정이지만 명시적으로 남김)
EXPOSE 443 5996 5997 9093 9094

ENV PGCT=connect-controller \
    PGCT_HOME=/opt/connect/controller \
    JAVA_TOOL_OPTIONS="-Djdk.lang.Process.launchMechanism=vfork -Dfile.encoding=UTF-8"

# dumb-init 로 zombie 방지, entrypoint에서 setup/legacy 후 supervisord 실행
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/entrypoint.sh"]
