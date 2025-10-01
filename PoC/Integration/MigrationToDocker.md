# MariaDB 컨테이너 실행 (10.6.21 버전)
docker run -d \
  --name pribit-mariadb \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_DATABASE=DB_PGZT \
  -v /path/to/your/mariadb/conf.d:/etc/mysql/conf.d \
  -v /path/to/your/init.sql:/docker-entrypoint-initdb.d/init.sql \
  -p 3306:3306 \
  mariadb:10.6.21

# Redis 컨테이너 실행 (7.4.2 버전)
docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf

docker 실행 시 에러 발생 

pribit@connect-controller:/opt/thirdparty/redis$ docker logs -f pribit-redis

*** FATAL CONFIG FILE ERROR (Redis 7.4.2) ***
Reading the configuration file, at line 25
>>> 'dir /var/lib/redis'
No such file or directory

/var/lib/redis 경로 추가해줌

docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf

pribit@connect-controller:/opt/thirdparty/redis$ docker logs -f pribit-redis

에러 발생

*** FATAL CONFIG FILE ERROR (Redis 7.4.2) ***
Can't open the log file: No such file or directory

/var/logs/redis 경로 추가해줌

docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -v /opt/thirdparty/redis/log:/var/log/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf

위 명령어는 Redis 7.4.2 컨테이너를 다음과 같이 실행합니다:

- `--name pribit-redis`  
  컨테이너 이름을 `pribit-redis`로 지정합니다.

- `-v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf`  
  호스트의 redis.conf 파일을 컨테이너 내부 설정 파일 위치에 마운트합니다.

- `-v pribit-redis-data:/var/lib/redis`  
  Redis 데이터가 저장될 경로를 Docker 볼륨(`pribit-redis-data`)으로 마운트합니다.

- `-v /opt/thirdparty/redis/log:/var/log/redis`  
  Redis 로그 디렉토리를 호스트의 `/opt/thirdparty/redis/log`로 마운트합니다.

- `-p 6379:6379`  
  호스트의 6379 포트를 컨테이너의 6379 포트에 연결합니다.

- `redis:7.4.2`  
  Redis 7.4.2 이미지를 사용합니다.

- `redis-server /usr/local/etc/redis/redis.conf`  
  컨테이너에서 redis-server를 지정된 설정 파일로 실행합니다.

**요약:**  
호스트의 설정/로그/데이터를 컨테이너에 마운트하여, 커스텀 설정과 영속적 데이터/로그 저장이 가능한 Redis 서버를 실행하는 명령어입니다.

pribit@connect-controller:/opt/thirdparty/redis$ docker logs -f pribit-redis

에러 발생

*** FATAL CONFIG FILE ERROR (Redis 7.4.2) ***
Can't open the log file: Permission denied


docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -v /opt/thirdparty/redis/log:/var/log/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf

에러 발생 

1:C 26 Sep 2025 02:44:47.156 # WARNING Memory overcommit must be enabled! Without it, a background save or replication may fail under low memory condition. Being disabled, it can also cause failures without low memory condition, see https://github.com/jemalloc/jemalloc/issues/1328. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
15:C 26 Sep 2025 02:44:47.158 * oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
15:C 26 Sep 2025 02:44:47.158 * Redis version=7.4.2, bits=64, commit=00000000, modified=0, pid=15, just started
15:C 26 Sep 2025 02:44:47.158 * Configuration loaded

docker run --name redis-server --sysctl vm.overcommit_memory=1 -p 6379:6379 -d redis:latest 

--sysctl vm.overcommit_memory=1 를 추가해주라 


docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -v /opt/thirdparty/redis/log:/var/log/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf


  # 호스트에서 직접 설정
sudo sysctl vm.overcommit_memory=1

# 영구 설정
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf


docker run -d \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -v /opt/thirdparty/redis/log:/var/log/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf

redis 설정 파일 검증  
``` 
# redis-server --test-config /opt/thirdparty/redis/redis.conf  
```

redis.conf 설정 다시 변경  

```
# Redis JSON 모듈 로드 (주석 처리 - 모듈이 없는 경우)
# loadmodule /etc/redis/plugin/librejson.so

# Docker 컨테이너에서는 모든 인터페이스에서 접속 허용
bind 0.0.0.0
protected-mode yes
port 6379
masterauth ff578d7bce0f2eeb37a2c9131b707776549fe5ae917f7c9a35d4f8cb95ba439f
requirepass ff578d7bce0f2eeb37a2c9131b707776549fe5ae917f7c9a35d4f8cb95ba439f
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Docker 컨테이너에서는 daemonize를 no로 설정
daemonize no
supervised auto
#pidfile /var/lib/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
save ''
databases 16
always-show-logo no
set-proc-title yes
proc-title-template "{title} {listen-addr} {server-mode}"
locale-collate ""
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
rdb-del-sync-files no
dir /var/lib/redis
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync yes
repl-diskless-sync-delay 5
repl-diskless-sync-max-replicas 0
repl-diskless-load disabled
repl-disable-tcp-nodelay no
replica-priority 100
acllog-max-len 128
rename-command CONFIG ""
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
lazyfree-lazy-user-del no
lazyfree-lazy-user-flush no
oom-score-adj no
oom-score-adj-values 0 200 800
disable-thp yes
appendonly no
appendfilename "appendonly.aof"
appenddirname "appendonlydir"
appendfsync no
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
aof-timestamp-enabled no
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-listpack-entries 512
hash-max-listpack-value 64
list-max-listpack-size -2
list-compress-depth 0
set-max-intset-entries 512
set-max-listpack-entries 128
set-max-listpack-value 64
zset-max-listpack-entries 128
zset-max-listpack-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
jemalloc-bg-thread yes
```

docker run -d \
  --user redis \
  --name pribit-redis \
  -v /opt/thirdparty/redis/redis.conf:/usr/local/etc/redis/redis.conf \
  -v pribit-redis-data:/var/lib/redis \
  -v /opt/thirdparty/redis/log:/var/log/redis \
  -p 6379:6379 \
  redis:7.4.2 \
  redis-server /usr/local/etc/redis/redis.conf


docker run

root@connect-controller:/opt/connect/logs# docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS          PORTS                                         NAMES
4fb7aa5cd704   redis:7.4.2   "docker-entrypoint.s…"   47 minutes ago   Up 47 minutes   0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp   pribit-redis

Web Server Re-Start 
``` 
# systemctl status connect-controller-web  
``` 






이제 mariadb 올리는 작업 진행

docker run -d \
  --name pribit-mariadb \
  -e MYSQL_ROOT_PASSWORD='Pribit2560!' \
  -e MYSQL_DATABASE=DB_PGZT \
  -e MYSQL_USER='pribit' \
  -e MYSQL_PASSWORD='Packetgo2560!' \
  -v /home/pribit/init.sql:/docker-entrypoint-initdb.d/init.sql \
  -p 3306:3306 \
  mariadb:10.6.21 







