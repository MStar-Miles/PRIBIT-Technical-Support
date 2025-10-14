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



docker compose 를 설치하여 compose 로 up down 실행


ExecStart=/usr/bin/java -server \
  -Dpgct=connect-controller \
  -Dpgct.home=/opt/connect/controller \
  -Dfile.encoding=UTF-8 \
  -Djdk.lang.Process.launchMechanism=vfork \
  -Xms2048m -Xmx3072m \
  -jar /opt/connect/controller/rpc/controller-rpc-1.0.jar

java -jar /opt/connect/controller/util/controller-util-1.0.jar setup pribit Packetgo2560! '127.0.0.1' DB_PGZT
controller-util jar 파일이 authenticate.properties 만들고, 내용을 암호화해서 저장한다. 

이 authenticate.properties 파일을 controller-rpc jar 가 실행되면서 DB 연결 설정 값들을 읽어 셋팅하는데, 

controller-rpc.jar 로그에는 Access denied for user 'pribit'@'172.18.0.1' (using password: YES) 
로 출력된다. 

설정대로라면 127.0.0.1 로 요청해야 하는데, 어떤 설정을 읽어서 처리하길래 172.18.0.1 로 요청하는 것일까? 
해당 시스템의 ip addr 명령어를 통해 인터페이스 ip들을 확인해봤다. 


root@connect-controller:/opt/connect/controller# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:be:26:4f brd ff:ff:ff:ff:ff:ff
    inet 10.0.30.156/24 brd 10.0.30.255 scope global ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:febe:264f/64 scope link
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether a6:91:89:f9:05:b0 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::a491:89ff:fef9:5b0/64 scope link
       valid_lft forever preferred_lft forever
53: br-22f30c474533: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether ce:ae:3c:84:86:f2 brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.1/16 brd 172.18.255.255 scope global br-22f30c474533
       valid_lft forever preferred_lft forever
    inet6 fe80::ccae:3cff:fe84:86f2/64 scope link
       valid_lft forever preferred_lft forever
56: vethdb9efb0@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-22f30c474533 state UP group default
    link/ether e6:30:b7:e3:f4:bf brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::e430:b7ff:fee3:f4bf/64 scope link
       valid_lft forever preferred_lft forever
57: veth5613ead@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-22f30c474533 state UP group default
    link/ether 3e:f7:05:7f:df:59 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::3cf7:5ff:fe7f:df59/64 scope link
       valid_lft forever preferred_lft forever

확인해보니 i/f br-22f30c474533 의 ip 를 가져가고 있다. 
controller-rpc-1.0.jar 파일에서 어떤 로직이 처리되길래 이런 상황이 발생하는지 jar 파일을 디컴파일하여 분석하고, 해당 내용을 조치하려고 한다. 



첫 번째 문제 
java -jar /opt/connect/controller/util/controller-util-1.0.jar setup pribit Packetgo2560! '127.0.0.1' DB_PGZT
mysql 접속 시 패스워드가 틀렸었고, DB_PGZT 스펠이 DB_PZGT 로 틀렸었다. 



docker inspect pribit-mariadb | grep -A5 -i "Networks" 
"NetworkSettings": 
  { 
    "Bridge": "", 
    "SandboxID": "6af977c31a6b54a4f0e0d244434ee0a4bb67ecee1ff76396f329f3407ac9bfce", 
    "SandboxKey": "/var/run/docker/netns/6af977c31a6b", 
    "Ports": 
    { 
      "3306/tcp": [ --
       "Networks": 
       { "pribit_default": 
       { "IPAMConfig": null, "Links": null, "Aliases": [ "pribit-mariadb",


지금 출력으로 보면 DB 컨테이너가 user-defined bridge 네트워크 pribit_default 위에 올라가 있다. 
이 네트워크의 게이트웨이(호스트 쪽 브리지 IP) 가 바로 172.18.0.1일 가능성이 높고, 
그래서 컨테이너(MariaDB) 입장에서는 클라이언트 소스 IP가 '172.18.0.1'로 보이는 것. 


[systemctl 에 등록된 서비스 목록] 

connect-controller-api.service      loaded    active   running PRIBIT Connect Controller API Application Service                  >
connect-controller-check.service    loaded    active   running PRIBIT Connect Controller Check Application Service                >
connect-controller-web.service      loaded    active   running PRIBIT Connect Controller Web Application Service                  >
connect-controller.service          loaded    active   running PRIBIT Connect Controller RPC Application Service                  >

nginx.service                       loaded    active   running The NGINX HTTP and reverse proxy server                            >

