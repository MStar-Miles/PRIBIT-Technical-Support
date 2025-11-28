#!/bin/bash

_name=$0

export W_HOME=/usr/local/pribit/wizard
export PATH_BACKUP_SYS=/usr/local/pribit/sys-backup
export PATH_DFT_CFG=${W_HOME}/default-config
export S_HOME=/usr/local/pribit/wizard/src-compile
export C_HOME=/usr/local/pribit/wizard/default-config

function fn_check_result(){
	if [ $1 -ne 0 ]; then
		echo "$2 fail"
		exit 1
	fi
}

function fn_compile_shellscript() {
    echo "fn_compile_shellscript"
    local _ret=0

    shc -f ${C_HOME}/thirdparty-conf-set.sh
    rm -f ${C_HOME}/thirdparty-conf-set.x.c
    rm -f ${C_HOME}/thirdparty-conf-set.sh
	mkdir -p /var/connect/gateway
	mv ${C_HOME}/thirdparty-conf-set.sh.x /var/connect/gateway/thirdparty-conf-set

    return 0
}

function fn_package_src_compile() {
	local _ret=0

	# 매직크립토(KCMVP) 설치
	cp -rf ${S_HOME}/libMagicCrypto.so /usr/lib/

	# OpenSSL 버전 변경 여부 체크
	local _OPENSSL_VERSION_FILE="${S_HOME}/openssl/VERSION.dat"
    local _MAJOR=$(grep '^MAJOR=' "$_OPENSSL_VERSION_FILE" | cut -d= -f2)
    local _MINOR=$(grep '^MINOR=' "$_OPENSSL_VERSION_FILE" | cut -d= -f2)
    local _PATCH=$(grep '^PATCH=' "$_OPENSSL_VERSION_FILE" | cut -d= -f2)
    local _VERSION="$_MAJOR.$_MINOR.$_PATCH"

	if [ "$(openssl version | awk '{print $2}')" != "$_VERSION" ]; then
		_need_reboot="true"
	fi
	# OpenSSL 설치
	cd ${S_HOME}/openssl
	./config
	fn_check_result $? "openssl_config"
	make -j 4 > /dev/null 2> /dev/null
	fn_check_result $? "openssl_make"
	make install > /dev/null
	fn_check_result $? "openssl_install"
	mv /usr/bin/openssl /usr/bin/openssl-1.1.1f
	ln -s /usr/local/bin/openssl /usr/bin/openssl

    _CHECK_LD_LIB_PATH=$(grep -r "/usr/local/lib64" /etc/ld.so.conf.d/libc.conf | awk '{print}')
    if [ -z "$_CHECK_LD_LIB_PATH" ]; then
      echo "/usr/local/lib64" >> /etc/ld.so.conf.d/libc.conf
    fi
    ldconfig

	# nginx 설치
	cd ${S_HOME}
	tar -zxvf headers-more-nginx-module-0.38.tar.gz > /dev/null
	
	tar -zxvf nginx-1.28.0.tar.gz > /dev/null
	cd ${S_HOME}/nginx-1.28.0
	
	./configure --prefix=/usr/share/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--lock-path=/var/lock/nginx.lock \
	--pid-path=/run/nginx.pid \
	--modules-path=/etc/nginx/modules \
	--with-pcre \
	--with-http_addition_module --with-http_auth_request_module \
	--with-http_dav_module --with-http_flv_module \
	--with-http_gunzip_module --with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_realip_module --with-http_secure_link_module \
	--with-http_slice_module --with-http_ssl_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_image_filter_module \
	--add-module=../headers-more-nginx-module-0.38
	fn_check_result $? "nginx_config"

	make > /dev/null
	fn_check_result $? "nginx_make"
	make install > /dev/null
	fn_check_result $? "nginx_install"

	# strongswan(IPSec) 설치
	rm /usr/local/etc/strongswan.d/charon.conf 2> /dev/null # 설정파일 갱신이 필요하므로 삭제하자. 있으면 make install에서 갱신이 안된다.
	cd ${S_HOME}/strongswan
	autoreconf -vif
	./configure --enable-eap-identity --enable-eap-mschapv2 --enable-eap-aka --enable-xauth-eap --enable-md4 --enable-openssl --enable-bypass-lan --enable-dhcp --enable-stroke
	make > /dev/null 2> /dev/null
	make install > /dev/null 2> /dev/null
	systemctl enable strongswan-starter

	# 커널 드라이버 복사
	local _kernel_file=xfrm_algo.ko
	if [ "$(lsb_release -r | awk '{ print $2 }')" == "24.04" ]; then
		_kernel_file=xfrm_algo.ko.zst
	fi
	cp ${S_HOME}/strongswan_additional/${_kernel_file} /lib/modules/$(uname -r)/kernel/net/xfrm/
	rmmod xfrm_user xfrm_algo 2> /dev/null
	insmod /lib/modules/$(uname -r)/kernel/net/xfrm/${_kernel_file}
	insmod /lib/modules/$(uname -r)/kernel/net/xfrm/xfrm_user.ko

	# 데이터플로우 모듈 컴파일
	cd ${S_HOME}
	tar -zxvf syn_gateway_install_pkg_20241128.tar.gz > /dev/null
	cd ${S_HOME}/syn_gateway_install_pkg
	systemctl stop syn_driver 2> /dev/null
	systemctl stop syn_gateway 2> /dev/null
	mkdir -p /var/syn_gateway/
	cd syn_driver
	sudo make clean > /dev/null 2> /dev/null
	sudo make > /dev/null 2> /dev/null
	cd ../
	chmod +x *.sh
	cp -a * /var/syn_gateway
	cp syn_gateway.service /usr/lib/systemd/system
	cp syn_driver.service /usr/lib/systemd/system
	rm /var/syn_gateway/syn_driver/Makefile
	rm /var/syn_gateway/syn_driver/modules.order
	rm /var/syn_gateway/syn_driver/syn_driver.c
	rm /var/syn_gateway/syn_driver/syn_driver.mod
	rm /var/syn_gateway/syn_driver.service
	rm /var/syn_gateway/syn_driver_service.txt
	rm /var/syn_gateway/syn_gateway.service
	rm /var/syn_gateway/syn_gateway_install.sh
	rm /var/syn_gateway/syn_driver.ko
	systemctl enable syn_gateway
	systemctl enable syn_driver

	# SSL VPN DCO 설치
	cd ${S_HOME}/ovpn-dco
	make > /dev/null 2> /dev/null
	make install
	modprobe ovpn-dco-v2

	# SSL VPN DCO 와 strongswan KCMVP 통신모듈 설치
	pkill mc_crypto_app 2> /dev/null
	rmmod mc_aria_skcipher 2> /dev/null
	rm /lib/modules/$(uname -r)/kernel/crypto/mc_aria_skcipher.ko 2> /dev/null
	cd ${S_HOME}/strongswan/pribit_additional/kernel_mc_aria
	make > /dev/null 2> /dev/null
	make install
	modprobe mc-aria-v1

	return 0
}

function fn_pause_exit(){
  echo "Please try again from the beginning."
  echo
  read -s -n 1 -p "Press any Key to Exit..."
  echo
  exit
}

function fn_exceed_count(){
  _EXCEED_CNT=$1
  if [ $_EXCEED_CNT -gt 5 ]; then
    echo "========================================================================================="
    echo "You have exceeded the number of times you can input."
    fn_pause_exit
  fi
}

function check_keyboard_sequence() {
  local checkKeyboardSequence=$1
  local checkKeyboardSequence_lower=$(echo "$checkKeyboardSequence" | tr '[:upper:]' '[:lower:]')
  local keyboard_rows=("qwertyuiop" "asdfghjkl" "zxcvbnm" "1234567890")

  for row in "${keyboard_rows[@]}"; do
    local row_len=${#row}
    for ((i=0; i<=row_len-4; i++)); do
      local seq="${row:i:4}"
      if [[ "$checkKeyboardSequence_lower" == *"$seq"* ]]; then
        return 0
      fi
      local rev_seq=$(echo "$seq" | rev)
      if [[ "$checkKeyboardSequence_lower" == *"$rev_seq"* ]]; then
        return 0
      fi
    done
  done

  return 1
}

function check_username_substring() {
  local compareValue=$1
  local checkInputValue=$2
  local compareValue_lower=$(echo "$compareValue" | tr '[:upper:]' '[:lower:]')
  local checkInputValue_lower=$(echo "$checkInputValue" | tr '[:upper:]' '[:lower:]')
  local compareValue_len=${#compareValue_lower}
  for ((i=0; i<=compareValue_len-4; i++)); do
    for ((j=4; j<=compareValue_len-i; j++)); do
      local substr="${compareValue_lower:i:j}"
      if [[ "$checkInputValue_lower" == *"$substr"* ]]; then
        return 0
      fi
    done
  done
  return 1
}

function fn_validate_auth() {
  local TARGET_PW=$1

  local PW_LEN="${#TARGET_PW}"
  local INPUT_CNT=1

  while true
  do
    if [ -z "$TARGET_PW" ]; then
      echo "Sorry, you can't use an empty password here.($INPUT_CNT/5)"
      ((INPUT_CNT++))
      fn_exceed_count $INPUT_CNT
      echo
      echo -n "Enter in-memory DB new AUTH: "
      stty -echo
      read TARGET_PW
      stty echo
      echo
      PW_LEN="${#TARGET_PW}"
    else
      if [[ "$TARGET_PW" == *" "* ]]; then
        echo "Password cannot contain spaces.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fn_exceed_count $INPUT_CNT
        echo
      	echo -n "Enter in-memory DB new AUTH: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif echo "$TARGET_PW" | grep -E '(.)\1\1' > /dev/null; then
        echo "Password cannot contain 3 or more consecutive repeated characters.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fn_exceed_count $INPUT_CNT
        echo
    	  echo -n "Enter in-memory DB new AUTH: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif check_username_substring "$TARGET_USR" "$TARGET_PW"; then
        echo "Password cannot contain 4 or more consecutive characters from username.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fn_exceed_count $INPUT_CNT
        echo
	      echo -n "Enter in-memory DB new AUTH: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif check_keyboard_sequence "$TARGET_PW"; then
        echo "Password cannot contain 4 or more consecutive keyboard characters.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fn_exceed_count $INPUT_CNT
        echo
      	echo -n "Enter in-memory DB new AUTH: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif [ $PW_LEN -gt 8 -a $PW_LEN -lt 17 ]; then
        echo "$TARGET_PW" | grep "[a-z]" | grep "[A-Z]" | grep "[0-9]" | grep "[!@#$%^&*]" >> /dev/null
        if [[ $? -eq 0 ]]; then
          break
        else
          echo "Password must contain atleast 1 uppercase, lowercase, digits and special characters.($INPUT_CNT/5)"
          ((INPUT_CNT++))
          fn_exceed_count $INPUT_CNT
          echo
       	  echo -n "Enter in-memory DB new AUTH: "
          stty -echo
          read TARGET_PW
          stty echo
          echo
          PW_LEN="${#TARGET_PW}"
        fi
      else
        echo "Password must be greater then 8 and lower then 17 characters!($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fn_exceed_count $INPUT_CNT
        echo
      	echo -n "Enter in-memory DB new AUTH: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      fi
    fi
  done

  _INMEMORYDB_AUTH=$TARGET_PW
}

function fn_compare_inputs(){
  local _FIRST_INPUT=$1
  local _SECOND_INPUT=$2
  local _COMPARE_TARGET_CNT=1

  while true
  do
    if [ "$_FIRST_INPUT" != "$_SECOND_INPUT" ]; then
      echo "Sorry, AUTH do not match.($_COMPARE_TARGET_CNT/5)"
      ((_COMPARE_TARGET_CNT++))
      fn_exceed_count $_COMPARE_TARGET_CNT
      echo
      echo -n "Re-enter in-memory DB new AUTH: "
      stty -echo
      read _SECOND_INPUT
      stty echo
      echo
    else
      break
    fi
  done
}

function fn_inmemorydb_input_set_password(){
  echo "========================================================================================="
  echo -n "Enter in-memory DB new AUTH: "
  stty -echo
  read _INMEMORYDB_AUTH
  stty echo
  echo
  fn_validate_auth $_INMEMORYDB_AUTH

  echo -n "Re-enter in-memory DB new AUTH: "
  stty -echo
  read _INMEMORYDB_CHK_AUTH
  stty echo
  echo
  fn_compare_inputs $_INMEMORYDB_AUTH $_INMEMORYDB_CHK_AUTH
}

function fn_make_gateway_properties() {
  _CHECK_FILE=/var/connect/gateway/util/gateway-util-1.0.jar
  if [ -f "$_CHECK_FILE" ]; then
    java -jar ${_CHECK_FILE} inmemorydb 127.0.0.1 $_REDIS_AUTH
  else
    java -jar ${_PATH_PACKAGE}/gateway-util/gateway-util-1.0.jar inmemorydb 127.0.0.1 $_REDIS_AUTH
  fi
  _RESULT_FILE=/var/connect/gateway/system-integrity/inmemorydb.pgd
  if [ -f "$_RESULT_FILE" ]; then
    chmod 700 $_RESULT_FILE
  fi
}

function fnMakeRedisServiceFile() {
  /usr/bin/cat << EOF > /etc/systemd/system/redis-server.service
[Unit]
Description=Advanced key-value store
After=network.target
Documentation=http://redis.io/documentation, man:redis-server(1)

[Service]
Type=notify
LimitNOFILE=infinity
ExecStartPre=${_PATH_REDIS}/redis-conf-set --redis_decode
ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
ExecStop=/bin/kill -s QUIT \$MAINPID
ExecStartPost=${_PATH_REDIS}/redis-conf-set --redis_post
PIDFile=/run/redis/redis-server.pid
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=2755

UMask=007
PrivateTmp=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
ReadWriteDirectories=-/var/lib/redis
ReadWriteDirectories=-/var/log/redis
ReadWriteDirectories=-/run/redis
ReadWriteDirectories=-${_PATH_REDIS}

NoNewPrivileges=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
MemoryDenyWriteExecute=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true

ProtectSystem=true
ReadWriteDirectories=-/etc/redis

[Install]
WantedBy=multi-user.target
Alias=redis.service
EOF
  chmod 644 /etc/systemd/system/redis-server.service
}

function fnMakeRedisConfFile() {
  _HMAC_USER_PW=$(echo -n $_REDIS_AUTH | openssl dgst -sha256 -hmac "pribittechnology" | awk '{print $2}')
  mkdir -p ${_PATH_REDIS}
  /usr/bin/cat << EOF > ${_PATH_REDIS}/redis.conf
loadmodule /etc/redis/plugin/librejson.so
bind 127.0.0.1
protected-mode yes
port 6379
masterauth $_HMAC_USER_PW
requirepass $_HMAC_USER_PW
rename-command CONFIG ""
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised auto
pidfile /run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
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
EOF
  chmod 640 ${_PATH_REDIS}/redis.conf
}

function fnEncodeRedisConf() {
  cp ${_PRIBIT_ENCODER} ${_PATH_REDIS}/pribit_redis_encoder
  ${_PATH_REDIS}/pribit_redis_encoder ${_PATH_REDIS}/redis.conf
  rm -f ${_PATH_REDIS}/redis.conf
  chown -R redis:redis ${_PATH_REDIS}/
}

function fnMakeRedisConfSetFile() {
  /usr/bin/cat << EOF > ${_PATH_REDIS}/redis-conf-set.sh
#!/bin/bash

function fnRedisConfFileDecode() {
    ${_PATH_REDIS}/pribit_redis_encoder ${_PATH_REDIS}/redis.conf.enc
    mv ${_PATH_REDIS}/redis.conf /etc/redis/redis.conf
    chmod 640 /etc/redis/redis.conf
    chown redis:redis /etc/redis/redis.conf
    return 0
}

function fnRedisConfFileRemove() {
    /usr/bin/rm -f /etc/redis/redis.conf
    return 0
}

function fn_help() {
    echo
    echo "Usage : \$0 [OPTIONS]"
    echo "OPTIONS := "
    echo "--redis_decode                                decode redis.conf file"
    echo "--redis_post                                  remove redis.conf file"
    echo
    echo "Example : "
    echo
    echo "    \$0 --redis_decode"
    echo "    \$0 --redis_post"
    echo
    exit 1
}

if [ \$# -eq 0 ]; then
    fn_help
else
    for i in "\$@"
    do
    case \$i in
        --redis_decode)
            fnRedisConfFileDecode;;
        --redis_post)
            fnRedisConfFileRemove;;
        --help)
            fn_help;;
        *)
            fn_help;;
    esac
    done
fi
EOF
}

function fnRedisConfSetFileBinary() {
  shc -f ${_PATH_REDIS}/redis-conf-set.sh
  rm -f ${_PATH_REDIS}/redis-conf-set.sh ${_PATH_REDIS}/redis-conf-set.sh.x.c
  mv ${_PATH_REDIS}/redis-conf-set.sh.x ${_PATH_REDIS}/redis-conf-set
  chmod 700 ${_PATH_REDIS}/redis-conf-set
  chown redis:redis ${_PATH_REDIS}/redis-conf-set
}

function fnRedisSetting() {
  echo "========================================================================================="
  echo "fnRedisSetting"
  echo "========================================================================================="
  # STEP  1 : STOP REDIS SERVICE
  systemctl stop redis-server.service
  # STEP  2 : DISABLE REDIS SERVICE
  systemctl disable redis-server.service
  # STEP  3 : DELETE FILE redis-server.service
  find / -type f -name redis-server.service 2>/dev/null | xargs rm -f
  # STEP  4 : CREATE FILE redis-server.service
  fnMakeRedisServiceFile
  # STEP  5 : CREATE FILE redis.conf
  fnMakeRedisConfFile
  # STEP  6 : ENCODE FILE redis.conf.enc
  fnEncodeRedisConf
  # STEP  7 : CREATE FILE redis-conf-set.sh
  fnMakeRedisConfSetFile
  # STEP  8 : CHANGE BINARY FILE redis-conf-set
  fnRedisConfSetFileBinary
  # STEP  9 : DAEMON RELOAD
  systemctl daemon-reload
  # STEP 10 : ENABLE REDIS SERVICE
  systemctl enable redis-server.service
  # STEP 11 : START REDIS SERVICE
  systemctl restart redis-server.service
  echo "========================================================================================="
  echo "fnRedisSetting is complete"
  echo "========================================================================================="
}

function fn_disable_kernel_update(){
	echo "disable kernel update"
	mv /etc/apt/apt.conf.d/10periodic{,_backup}
	chown root:root ${C_HOME}/apt/10periodic
	cp ${C_HOME}/apt/10periodic /etc/apt/apt.conf.d/
	sudo systemctl disable apt-daily.timer
	sudo systemctl disable apt-daily-upgrade.timer
}

function fn_history(){
	echo "fn_history"
	
	local _file="/etc/profile"
	
	_history=`/bin/cat ${_file} | grep HISTTIMEFORMAT`
	
	if [ -z "${_history}" ]; then
		echo 'HISTTIMEFORMAT="[%F %T]  "' >> ${_file}
		echo "export HISTTIMEFORMAT"	>> ${_file}
	fi
}

function fn_fw_mobile_enable() {
	echo "fn_fw_mobile_enable"

	/sbin/iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1252
	/sbin/iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1252
    /usr/sbin/netfilter-persistent save
	return 0;	
}

function fn_sshd_config() {
	echo "fn_sshd_config"
	if [ ! -f "${PATH_BACKUP_SYS}/sshd_config" ]; then
		echo "--- sshd config backup ---"
		cp -f /etc/ssh/sshd_config ${PATH_BACKUP_SYS}/sshd_config
	fi

	local _sshd_port=$(grep -E '^\s*Port' /etc/ssh/sshd_config)
	cat /dev/null > /etc/ssh/sshd_config
	
	echo -e "SyslogFacility AUTH" >> /etc/ssh/sshd_config
	echo -e "LogLevel INFO" >> /etc/ssh/sshd_config
	echo -e "PermitRootLogin no" >> /etc/ssh/sshd_config
	echo -e "MaxAuthTries 3" >> /etc/ssh/sshd_config
	echo -e "MaxSessions 3" >> /etc/ssh/sshd_config
	echo -e "LoginGraceTime 30" >> /etc/ssh/sshd_config
	echo -e "StrictModes yes" >> /etc/ssh/sshd_config
	echo -e "IgnoreRhosts yes" >> /etc/ssh/sshd_config
	echo -e "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
	echo -e "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
	echo -e "UsePAM yes" >> /etc/ssh/sshd_config
	echo -e "AcceptEnv LANG LC_*" >> /etc/ssh/sshd_config
	echo -e "Subsystem       sftp    /usr/lib/openssh/sftp-server" >> /etc/ssh/sshd_config

	echo -e "root    hard    maxlogins    1" >>  /etc/security/limits.conf

	# ssh 포트는 저장해 뒀다가 새 설정에 끼워넣는다
	echo -e "${_sshd_port}" >> /etc/ssh/sshd_config

	return 0;
}

function fn_kernel_param() {
	echo "fn_kernel_param"
	if [ ! -f "${PATH_BACKUP_SYS}/sysctl.conf.orig" ]; then
		echo "--- sysctl.conf backup ---"
		cp -f /etc/sysctl.conf ${PATH_BACKUP_SYS}/sysctl.conf.orig
	fi
	
	cat /dev/null > /etc/sysctl.conf
	
	echo -e "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

	echo -e "kernel.printk = 4 4 1 7" >> /etc/sysctl.conf 
	echo -e "kernel.panic = 10" >> /etc/sysctl.conf 
	echo -e "kernel.sysrq = 0" >> /etc/sysctl.conf 
	echo -e "kernel.shmmax = 4294967296" >> /etc/sysctl.conf 
	echo -e "kernel.shmall = 4194304" >> /etc/sysctl.conf 
	echo -e "kernel.core_uses_pid = 1" >> /etc/sysctl.conf 
	echo -e "kernel.msgmnb = 65536" >> /etc/sysctl.conf 
	echo -e "kernel.msgmax = 65536" >> /etc/sysctl.conf 
	echo -e "vm.swappiness = 20" >> /etc/sysctl.conf 
	echo -e "vm.dirty_ratio = 80" >> /etc/sysctl.conf 
	echo -e "vm.dirty_background_ratio = 5" >> /etc/sysctl.conf 
	echo -e "net.core.netdev_budget=600" >> /etc/sysctl.conf
	echo -e "net.core.netdev_max_backlog = 262144" >> /etc/sysctl.conf 
	echo -e "net.core.rmem_default = 31457280" >> /etc/sysctl.conf 
	echo -e "net.core.rmem_max = 67108864" >> /etc/sysctl.conf 
	echo -e "net.core.wmem_default = 31457280" >> /etc/sysctl.conf 
	echo -e "net.core.wmem_max = 67108864" >> /etc/sysctl.conf 
	echo -e "net.core.somaxconn = 65535" >> /etc/sysctl.conf 
	echo -e "net.core.optmem_max = 25165824" >> /etc/sysctl.conf 
	echo -e "net.ipv4.neigh.default.gc_thresh1 = 4096" >> /etc/sysctl.conf 
	echo -e "net.ipv4.neigh.default.gc_thresh2 = 8192" >> /etc/sysctl.conf 
	echo -e "net.ipv4.neigh.default.gc_thresh3 = 16384" >> /etc/sysctl.conf 
	echo -e "net.ipv4.neigh.default.gc_interval = 5" >> /etc/sysctl.conf 
	echo -e "net.ipv4.neigh.default.gc_stale_time = 120" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_slow_start_after_idle = 0" >> /etc/sysctl.conf 
	echo -e "net.ipv4.ip_local_port_range = 1024 65000" >> /etc/sysctl.conf 
	echo -e "net.ipv4.ip_no_pmtu_disc = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.route.flush = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.route.max_size = 8048576" >> /etc/sysctl.conf 
	echo -e "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_congestion_control = htcp" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_mem = 65536 131072 262144" >> /etc/sysctl.conf 
	echo -e "net.ipv4.udp_mem = 65536 131072 262144" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_rmem = 4096 87380 33554432" >> /etc/sysctl.conf 
	echo -e "net.ipv4.udp_rmem_min = 16384" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_wmem = 4096 87380 33554432" >> /etc/sysctl.conf 
	echo -e "net.ipv4.udp_wmem_min = 16384" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_max_tw_buckets = 1440000" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_max_orphans = 400000" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_window_scaling = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_rfc1337 = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_synack_retries = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_syn_retries = 2" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_max_syn_backlog = 16384" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_timestamps = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_fack = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_ecn = 2" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_fin_timeout = 10" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_keepalive_time = 600" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_keepalive_intvl = 60" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_keepalive_probes = 10" >> /etc/sysctl.conf 
	echo -e "net.ipv4.tcp_no_metrics_save = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf 
	echo -e "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf 
	echo -e "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf 
	echo -e "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf 
	echo -e "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf

	/sbin/sysctl -p
	return 0;
}

function fn_kernel_file_param() {
	echo "fn_kernel_file_param"
	echo -e "root	soft	nofile	65535" >> /etc/security/limits.conf
	echo -e "root	hard	nofile	65535" >> /etc/security/limits.conf
	echo -e "root	soft	nproc	65535" >> /etc/security/limits.conf
	echo -e "root	hard	nproc	65535" >> /etc/security/limits.conf

	echo -e "session required pam_limits.so" >> /etc/pam.d/common-session

	return 0;
}

function fn_ssh_banner() {
	chmod -x /etc/update-motd.d/00-header
	chmod -x /etc/update-motd.d/10-help-text
	chmod -x /etc/update-motd.d/50-motd-news
	chmod -x /etc/update-motd.d/90-updates-available
	chmod -x /etc/update-motd.d/91-release-upgrade
	chmod -x /etc/update-motd.d/92-unattended-upgrades
	chmod -x /etc/update-motd.d/98-reboot-required
	
	echo -e "Banner /var/connect/gateway/etc/banner" >> /etc/ssh/sshd_config
	
	return 0;
}

function fn_password_complexitys() {
	echo "fn_password_complexitys"

	cp /etc/pam.d/common-auth{,.bak} 2> /dev/null
	cp /etc/pam.d/common-password{,.bak} 2> /dev/null
	cp /etc/pam.d/login{,.bak} 2> /dev/null
	cp /etc/pam.d/su{,.bak} 2> /dev/null
	cp /etc/security/faillock.conf{,.bak} 2> /dev/null
	cp /etc/login.defs{,.bak} 2> /dev/null
	cp /etc/fail2ban/jail.local{,.bak} 2> /dev/null
	
	cp -rf ${W_HOME}/default-config/account/pam_pribit.so /usr/lib/x86_64-linux-gnu/security/
	cp -rf ${W_HOME}/default-config/account/common-auth /etc/pam.d/
	cp -rf ${W_HOME}/default-config/account/common-password /etc/pam.d/
	cp -rf ${W_HOME}/default-config/account/login /etc/pam.d/
	cp -rf ${W_HOME}/default-config/account/su /etc/pam.d/
	
	cp -rf ${W_HOME}/default-config/account/faillock.conf /etc/security/
	cp -rf ${W_HOME}/default-config/account/jail.local /etc/fail2ban/

	cp -rf ${W_HOME}/default-config/account/login.defs /etc/

	return 0
}

function fn_rsyslog_config() {
	echo "fn_rsyslog_config"

	if [ ! -f "/etc/rsyslog.d/pribit_log.conf" ]; then
		cp -f ${PATH_DFT_CFG}/rsyslog/pribit_log.conf /etc/rsyslog.d/pribit_log.conf
		chmod 0644 /etc/rsyslog.d/pribit_log.conf
	fi

	if [ ! -f "/etc/rsyslog.d/10-dhcpd.conf" ]; then
		cp -f ${PATH_DFT_CFG}/rsyslog/10-dhcpd.conf /etc/rsyslog.d/10-dhcpd.conf
		chmod 0644 /etc/rsyslog.d/10-dhcpd.conf
	fi

	if [ ! -f "/etc/logrotate.d/10-dhcpd" ]; then
		cp -f ${PATH_DFT_CFG}/rsyslog/10-dhcpd /etc/logrotate.d/10-dhcpd
		chmod 0644 /etc/logrotate.d/10-dhcpd
	fi

	systemctl restart rsyslog.service	

	if [ ! -f "/etc/cron.d/logrotate" ]; then
		cp -f ${PATH_DFT_CFG}/rsyslog/logrotate /etc/cron.d/.
		chmod 0644 /etc/cron.d/logrotate
	fi

	systemctl restart cron.service	
	return 0;
}

function fn_connect_vpn_config() {
	echo "fn_connect_vpn_config"
	mkdir -p /var/connect/connect-vpn

	cp -rf ${PATH_DFT_CFG}/connect-vpn/connect-vpn/* /var/connect/connect-vpn/
	if [ "${_prevent_openvpn}" == "true" ]; then
		cp ${PATH_DFT_CFG}/connect-vpn/prevent/connect-vpn /var/connect/connect-vpn/
	fi

	# 업데이트일 경우에는 설정을 하지 않는다
	if [ "${_update}" == "false" ]; then
		if [ "${_ip_set_v6}" == "false" ]; then
			/var/connect/gateway/thirdparty-conf-set --connect_vpn_cacert_make --connect_vpn_cert_make --connect_vpn_conf tcp 443 $_server_farm $_sslvpn_network "$_dns_list"
		else
			/var/connect/gateway/thirdparty-conf-set --connect_vpn_cacert_make --connect_vpn_cert_make --connect_vpn_conf_with_ipv6 tcp 443 $_server_farm $_sslvpn_network "$_dns_list" $_server_farm_v6 $_sslvpn_network_v6 "$_dns_list_v6"
		fi
	else
		if [ ! -f "/var/connect/connect-vpn/certs/certfile.crypt" ]; then # 인증서 암호 파일을 KEK로 암호화하는 것으로 변경됨에 따라 기존 게이트웨이에서 업데이트할 경우 암호화 진행
			if [ -f "/var/connect/connect-vpn/certs/certfile.enc" ]; then # 인코딩버전이 있으면 디코딩하여 암호화
				/var/connect/connect-vpn/connect_encoder /var/connect/connect-vpn/cacerts/certfile.enc
				/var/connect/connect-vpn/connect_encoder /var/connect/connect-vpn/certs/certfile.enc
				rm -rf /var/connect/connect-vpn/cacerts/certfile.enc /var/connect/connect-vpn/certs/certfile.enc
			fi
			/var/connect/connect_encrypter /var/connect/connect-vpn/cacerts/certfile
			/var/connect/connect_encrypter /var/connect/connect-vpn/certs/certfile
			rm -rf /var/connect/connect-vpn/cacerts/certfile /var/connect/connect-vpn/certs/certfile
		fi
		# openssl 3.5 이후로 PQC가 kyber512에서 ML-KEM으로 바뀌고 oqsprivider도 사용하지 않게 되어 업데이트 시에도 설정파일 수정이 필요함
		/var/connect/connect-vpn/connect_encoder /var/connect/connect-vpn/conf/server.conf.enc
		sed -i '/providers default oqsprovider/{N; s/providers default oqsprovider\ntls-groups X25519:mc-p256r1:kyber512/tls-groups X25519:mc-p256r1:MLKEM768/}' /var/connect/connect-vpn/conf/server.conf
		/var/connect/connect-vpn/connect_encoder /var/connect/connect-vpn/conf/server.conf
		rm /var/connect/connect-vpn/conf/server.conf
	fi

	cp -f ${PATH_DFT_CFG}/connect-vpn/connect-vpn.service /etc/systemd/system/
	systemctl enable connect-vpn.service

	return 0;
}

function fn_nginx_config() {
    echo "fn_nginx_config"
    
    rm -rf /etc/nginx/*
	cp -f ${PATH_DFT_CFG}/nginx/nginx.service /etc/systemd/system/
	mkdir -p /var/local
	cp -rf ${PATH_DFT_CFG}/nginx/redirecthome /var/local/

	/var/connect/gateway/thirdparty-conf-set --nginx_conf --cert_make

    systemctl enable nginx
    
	return 0;
}

function fn_gateway_config() {
	echo "fn_gateway_config"

	mkdir -p /var/connect/gateway

	cp -rf ${PATH_DFT_CFG}/gateway/* /var/connect/gateway/.

	cp -f /var/connect/gateway/sys/connect-gateway.service /etc/systemd/system/
	cp -f /var/connect/gateway/sys/connect-gateway-check.service /etc/systemd/system/

	systemctl enable connect-gateway.service
	systemctl enable connect-gateway-check.service

	chmod 0640 /var/connect/gateway/etc/banner

	java -jar /var/connect/gateway/util/gateway-util-1.0.jar connect
		
	return 0;
}

function fn_ipsec_conf() {
	echo "fn_ipsec_conf"

	aa-complain /usr/lib/ipsec/charon
	aa-complain /usr/lib/ipsec/stroke
	aa-complain /usr/sbin/swanctl

	if [ ! -f "${PATH_BACKUP_SYS}/charon-logging.conf" ]; then
		echo "--- charon-logging config backup ---"
		cp -f /usr/local/etc/strongswan.d/charon-logging.conf ${PATH_BACKUP_SYS}/charon-logging.conf
		rm -f /usr/local/etc/strongswan.d/charon-logging.conf
	fi
	
	if [ ! -f "/usr/local/etc/strongswan.d/charon-logging.conf" ]; then
		cp -f ${PATH_DFT_CFG}/ipsec/charon-logging.conf /usr/local/etc/strongswan.d/
		cp -f ${PATH_DFT_CFG}/ipsec/vpn_log /etc/logrotate.d/

		touch /var/log/pribit/vpn-auth.log
		touch /var/log/pribit/vpn.log
		
		logrotate /etc/logrotate.conf	
	fi

	rm -f /usr/local/pribit/etc
	ln -s /etc /usr/local/pribit/etc
	cp -f ${PATH_DFT_CFG}/ipsec/strongswan-starter.service /lib/systemd/system/

	echo "ipsec cert, config create"
	cp -rf ${PATH_DFT_CFG}/ipsec/etc/* /usr/local/etc/
	mkdir -p /usr/local/etc/ipsec.d/conn
	touch /usr/local/etc/ipsec.d/conn/c_site.conf
	mkdir -p /usr/local/etc/ipsec.d/secrets
	touch /usr/local/etc/ipsec.d/secrets/ipsec.users.secrets
	chmod 0600 /usr/local/etc/ipsec.d/secrets/ipsec.users.secrets		

	# 업데이트일 경우에는 인증서 생성 및 설정을 하지 않는다
	if [ "${_update}" == "false" ]; then
		/var/connect/gateway/thirdparty-conf-set --ipsec_cacert_make packetgo.com --ipsec_cert_make gateway packetgo.com --ipsec_conf gateway packetgo.com $_server_farm $_ipsec_network
		/var/connect/gateway/thirdparty-conf-set --ipsec_pqc_cacert_make pqc.packetgo.com --ipsec_pqc_cert_make gateway pqc.packetgo.com
	fi

	# 인증서가 암호화되어 있지 않으면 암호화한다.
	if [ ! -f "/usr/local/etc/ipsec.d/private/ca.packetgo.com.certfile.crypt" ]; then
		local _IPSEC_CAKEY_PW=$(/usr/bin/openssl rand -base64 12)
		echo "$_IPSEC_CAKEY_PW" > /usr/local/etc/ipsec.d/private/ca.packetgo.com.certfile
		/var/connect/connect_encrypter /usr/local/etc/ipsec.d/private/ca.packetgo.com.certfile
		rm /usr/local/etc/ipsec.d/private/ca.packetgo.com.certfile
		openssl pkey -in /usr/local/etc/ipsec.d/private/ca.packetgo.com.key.pem -out /usr/local/etc/ipsec.d/private/ca.packetgo.com.key.pem_ -aes256 -passout pass:"$_IPSEC_CAKEY_PW"
		mv /usr/local/etc/ipsec.d/private/ca.packetgo.com.key.pem{_,}
	fi
	if [ ! -f "/usr/local/etc/ipsec.d/secrets/gateway.packetgo.com.secrets.crypt" ]; then
		local _IPSEC_KEY_PW=$(/usr/bin/openssl rand -base64 12)
		openssl pkey -in /usr/local/etc/ipsec.d/private/gateway.packetgo.com.key.pem -out /usr/local/etc/ipsec.d/private/gateway.packetgo.com.key.pem_ -aes256 -passout pass:"$_IPSEC_KEY_PW"
		mv /usr/local/etc/ipsec.d/private/gateway.packetgo.com.key.pem{_,}
		echo ": RSA /usr/local/etc/ipsec.d/private/gateway.packetgo.com.key.pem ${_IPSEC_KEY_PW}" > /usr/local/etc/ipsec.d/secrets/gateway.packetgo.com.secrets
		/var/connect/connect_encrypter /usr/local/etc/ipsec.d/secrets/gateway.packetgo.com.secrets
		rm /usr/local/etc/ipsec.d/secrets/gateway.packetgo.com.secrets
	fi
	if [ ! -f "/usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.certfile.crypt" ]; then
		local _IPSEC_CAKEY_PW=$(/usr/bin/openssl rand -base64 12)
		echo "$_IPSEC_CAKEY_PW" > /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.certfile
		/var/connect/connect_encrypter /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.certfile
		rm /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.certfile
		openssl pkey -in /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.key.pem -out /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.key.pem_ -aes256 -passout pass:"$_IPSEC_CAKEY_PW"
		mv /usr/local/etc/ipsec.d/private/ca.pqc.packetgo.com.key.pem{_,}
	fi
	if [ ! -f "/usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets.crypt" ]; then
		local _IPSEC_KEY_PW=$(/usr/bin/openssl rand -base64 12)
		openssl pkey -in /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem -out /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem_ -aes256 -passout pass:"$_IPSEC_KEY_PW"
		mv /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem{_,}
		echo ": Dilithium /usr/local/etc/ipsec.d/private/gateway.pqc.packetgo.com.key.pem ${_IPSEC_KEY_PW}" > /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets
		/var/connect/connect_encrypter /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets
		rm /usr/local/etc/ipsec.d/secrets/gateway.pqc.packetgo.com.secrets
	fi

	return 0;
}

function fn_default_config() {
	local _ret=0
	
	echo "default config"

	mkdir -p /var/connect
	cp ${C_HOME}/connect_encrypter /var/connect/

	fn_disable_kernel_update
	fn_check_result $? "fn_disable_kernel_update"

	echo -e "export TMOUT=300" >> /etc/profile
	
	fn_history
	source /etc/profile
	
	fn_fw_mobile_enable
	fn_check_result $? "fn_fw_mobile_enable"
	
	fn_kernel_param
	fn_check_result $? "fn_kernel_param"
		
	# 업데이트일 경우에는 설정을 하지 않는다
	if [ "${_update}" == "false" ]; then
		fn_kernel_file_param
		fn_check_result $? "fn_kernel_file_param"

		fn_sshd_config
		fn_check_result $? "fn_sshd_config"

		fn_ssh_banner
		fn_check_result $? "fn_ssh_banner"
	fi
			
	fn_password_complexitys
	fn_check_result $? "fn_password_complexitys"

	fn_rsyslog_config
	fn_check_result $? "fn_rsyslog_config"
			
	fn_connect_vpn_config
	fn_check_result $? "fn_connect_vpn_config"

	fn_nginx_config
	fn_check_result $? "fn_nginx_config"

	sed -i "s/Ubuntu 22.04/PacketGO 2.1/g" /etc/issue
	sed -i "s/Ubuntu 20.04.5/PacketGO 2.1/g" /etc/issue

	systemctl enable fail2ban

	fn_gateway_config
	fn_check_result $? "fn_gateway_config"

	fn_ipsec_conf
	fn_check_result $? "fn_ipsec_conf"
	
	chmod 700 -R /var/connect/
	chmod 700 -R /etc/nginx/
	chmod 700 -R /usr/local/etc/*
	chmod 700 -R /usr/local/libexec/ipsec/

	return 0;
}

function fn_delete_install_file(){
	#설치 파일 삭제
	rm -rf /var/connect/gateway/sys

	rm -rf /var/connect/gateway/system-integrity/svc-check.sh

	rm -rf /usr/local/pribit/*

	return 0;
}

function fn_daemon_restart(){
	systemctl daemon-reload
	systemctl restart connect-gateway-check
	systemctl restart connect-gateway
	systemctl restart connect-vpn
	systemctl restart strongswan-starter
	systemctl restart isc-dhcp-server
	systemctl restart isc-dhcp-server6
	systemctl restart nginx
	systemctl restart redis
	systemctl restart syn_driver
	systemctl restart syn_gateway
}

function fn_wizard(){
	local _ret=0
	_need_reboot="false"

	_CHECK_CONTROLLER_OR_GATEWAY="gateway"
	_PATH_REDIS=/var/connect-thirdparty/redis
	_PRIBIT_ENCODER=/var/connect/connect-vpn/connect_encoder
	# 업데이트일 경우에는 설정을 받을 필요가 없다.
	if [ "${_update}" == "false" ]; then
		# Redis 설정을 위해 비밀번호를 먼저 입력받음
		fn_inmemorydb_input_set_password
		_REDIS_AUTH=$_INMEMORYDB_AUTH

		local _server_farm_default="10.200.0.0/24"
		local _sslvpn_network_default="10.21.0.0/24"
		local _ipsec_network_default="10.20.0.0/24"
		local _server_farm_v6_default="fd00::10:200:0:0/112"
		local _sslvpn_network_v6_default="fd00::10:21:0:0/112"
		local _ipsec_network_v6_default="fd00::10:20:0:0/112"
		_server_farm=${_server_farm_default}
		_sslvpn_network=${_sslvpn_network_default}
		_ipsec_network=${_ipsec_network_default}
		_server_farm_v6=${_server_farm_v6_default}
		_sslvpn_network_v6=${_sslvpn_network_v6_default}
		_ipsec_network_v6=${_ipsec_network_v6_default}

		_reg_ipv4="((([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([1-9]?[0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))"
		_reg_ipv6="((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2}|([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3}|([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4}|([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5}|[0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6})|:((:[0-9A-Fa-f]{1,4}){1,7}|:)|fe80:(:[0-9A-Fa-f]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9A-Fa-f]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])))"
		_reg_netmask_len="([1-2]?[0-9]|3[0-2])"
		_reg_netmask_len_v6="([1-9]?[0-9]|1[01][0-9]|12[0-8])"
		_reg_cidr="(${_reg_ipv4}/${_reg_netmask_len})"
		_reg_cidr_v6="(${_reg_ipv6}/${_reg_netmask_len_v6})"
		# IP세팅을 설정해야 할 경우 입력받는다.
		if [ "${_ip_set}" == "true" ]; then
			#서버팜 대역 입력
			while :
			do
				echo -n "enter Server Farm(ex:10.200.0.0/24,192.168.200.0/24) :"
				read _server_farm
				_server_farm=${_server_farm:-${_server_farm_default}}
				if [[ $_server_farm =~ ^(${_reg_cidr},)*(${_reg_cidr})$ ]]; then
					break;
				fi
				echo "wrong CIDR. please reenter."
			done
			#DNS설정 입력
			while :
			do
				echo -n "enter DNS list(ex:168.126.63.1,8.8.8.8) :"
				read _dns_list
				if [[ $_dns_list =~ ^(${_reg_ipv4},)*(${_reg_ipv4})?$ ]]; then
					break;
				fi
				echo "wrong IP list. please reenter."
			done
			#SSLVPN 설정 입력
			while :
			do
				echo -n "enter SSL VPN Network(ex:10.21.0.0/24) :"
				read _sslvpn_network
				_sslvpn_network=${_sslvpn_network:-${_sslvpn_network_default}}
				if [[ $_sslvpn_network =~ ^${_reg_cidr}$ ]]; then
					break;
				fi
				echo "wrong CIDR. please reenter."
			done
			#IPSec 설정 입력
			while :
			do
				echo -n "enter IPSec VPN Network(ex:10.20.0.0/24) :"
				read _ipsec_network
				_ipsec_network=${_ipsec_network:-${_ipsec_network_default}}
				if [[ $_ipsec_network =~ ^${_reg_cidr}$ ]]; then
					break;
				fi
				echo "wrong CIDR. please reenter."
			done
			# IPV6세팅을 설정해야 할 경우 입력받는다.
			if [ "${_ip_set_v6}" == "true" ]; then
				#서버팜 대역 입력
				while :
				do
					echo -n "enter Server Farm(ex:fd00::10:200:0:0/112,fd00::192:168:200:0/112) :"
					read _server_farm_v6
					_server_farm_v6=${_server_farm_v6:-${_server_farm_v6_default}}
					if [[ $_server_farm_v6 =~ ^(${_reg_cidr_v6},)*(${_reg_cidr_v6})$ ]]; then
						break;
					fi
					echo "wrong CIDR. please reenter."
				done
				#DNS설정 입력
				while :
				do
					echo -n "enter DNS list(ex:0:0:0:0:0:ffff:a87e:3f01,0:0:0:0:0:ffff:808:404) :"
					read _dns_list_v6
					if [[ $_dns_list_v6 =~ ^(${_reg_ipv6},)*(${_reg_ipv6})?$ ]]; then
						break;
					fi
					echo "wrong IP list. please reenter."
				done
				#SSLVPN 설정 입력
				while :
				do
					echo -n "enter SSL VPN Network(ex:fd00::10:21:0:0/112) :"
					read _sslvpn_network_v6
					_sslvpn_network_v6=${_sslvpn_network_v6:-${_sslvpn_network_v6_default}}
					if [[ $_sslvpn_network_v6 =~ ^${_reg_cidr_v6}$ ]]; then
						break;
					fi
					echo "wrong CIDR. please reenter."
				done
				#IPSec 설정 입력
				while :
				do
					echo -n "enter IPSec VPN Network(ex:fd00::10:20:0:0/112) :"
					read _ipsec_network_v6
					_ipsec_network_v6=${_ipsec_network_v6:-${_ipsec_network_v6_default}}
					if [[ $_ipsec_network_v6 =~ ^${_reg_cidr_v6}$ ]]; then
						break;
					fi
					echo "wrong CIDR. please reenter."
				done
			fi
		fi
	fi

	echo "remove unused package"
	apt-get purge -y ufw nis tftpd atftpd tftpd-hpa telnet ftp snapd git libssl-dev
	apt-get autoremove -y
	apt-get autoclean

	mkdir -p ${PATH_BACKUP_SYS}
	mkdir -p /var/log/pribit/old

	if [ "${_off_line}" == "true" ]; then
		echo "intall PacketGo Off-Line Package"
		local _deb_files=${W_HOME}/archives/*.deb
		if [ "$(lsb_release -r | awk '{ print $2 }')" == "24.04" ]; then
			_deb_files=${W_HOME}/archives_24.04/*.deb
		fi
		dpkg -i $_deb_files
		if [ $? -ne 0 ]; then		# 설치와 설정 순서 문제로 한번에 설치가 안되는 경우가 나와서 설치 한 번 더 시도
			dpkg -i $_deb_files
		fi
		fn_check_result $? "off-line_install"
	else 	
		echo "install PacketGo Gateway"
		# redis 최신버전 설치를 위한 준비작업(https://redis.io/docs/latest/operate/oss_and_stack/install/install-redis/install-redis-on-linux/)
		apt-get update
		apt-get -y install lsb-release curl gpg
		curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/redis-archive-keyring.gpg
		chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg
		echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

		apt-get update
		local _install_lib="build-essential libpcre3-dev rdate zlib1g-dev libgd-dev libpam-pwquality openjdk-17-jre-headless"
		_install_lib+=" isc-dhcp-server shc netfilter-persistent fail2ban apparmor-utils python3 keepalived snmp snmpd redis-server"
		_install_lib+=" libxml2-dev uuid-dev libtss2-tcti-tabrmd0 bwm-ng"
		_install_lib+=" logrotate rsyslog cron"   # minimal 버전에는 안깔리는 패키지
		_install_lib+=" autoconf cmake libtool-bin gettext gperf flex bison libwolfssl-dev libbotan-2-dev libgmp-dev libgcrypt20-dev"	# StrongSwan(IPSec) 컴파일 관련 패키지
		_install_lib+=" libatomic1 libnetfilter-queue-dev libhiredis-dev libjsoncpp-dev libcrypto++-dev"  # 데이터플로우 모듈 관련 패키지
		apt-get -y install $_install_lib
		fn_check_result $? $_install_lib
	fi

	fn_compile_shellscript
	fn_check_result $? "fn_compile_shellscript"

	echo "compile 3rd-party source"
	fn_package_src_compile
	fn_check_result $? "fn_package_src_compile"

	fn_default_config
	fn_check_result $? "fn_default_config"

	# Redis 설정
	mkdir -p /etc/redis/plugin
	local _ubuntu_ver=20.04
	if [ "$(lsb_release -r | awk '{ print $2 }')" == "24.04" ]; then
		_ubuntu_ver=24.04
	fi
	cp -rf ${W_HOME}/default-config/redis/${_ubuntu_ver}/librejson.so /etc/redis/plugin/
	# 업데이트일 경우에는 설정을 하지 않는다
	if [ "${_update}" == "false" ]; then
		fn_make_gateway_properties
		fn_check_result $? "fn_make_gateway_properties"
		fnRedisSetting
		fn_check_result $? "fnRedisSetting"
	else  # 업데이트일 때도 서비스파일은 갱신한다.
		fnMakeRedisServiceFile
	fi

	_c_hostname=$(cat /etc/hostname)
	sed -i "s/$_c_hostname/packetgo-gateway/g" /etc/hosts
	hostnamectl set-hostname packetgo-gateway

	timedatectl set-timezone "Asia/Seoul"
	rdate -s time.bora.net

	fn_delete_install_file

	fn_daemon_restart

	echo "========================================================"
	echo "        PacketGo Gateway Install was completed."
	if [ "${_need_reboot}" == "true" ]; then
		echo "OpenSSL has been updated. A system reboot is required."
	fi
	echo "========================================================"
}

fn_help(){
	echo "Usage : $0 [OPTIONS]"
	echo "  OPTIONS := "
	echo "    --off_line              install off-line for PacketGo Gateway"
	echo "    --update                update PacketGo Gateway and don't change config"
	echo "    --update_java_only      update PacketGo Gateway JAVA module only"
	echo "    --ip_set                install PacketGo Gateway with VPN IP setting. don't work with --update"
	echo "    --ip_set_v6             install PacketGo Gateway with VPN IPV4 and IPV6 setting. don't work with --update"
	echo "    --prevent_openvpn       prevent openvpn client"
	echo "Example : "
	echo "  $0"
	echo "  $0 --off_line"
	echo "  $0 --update"
	echo "  $0 --off_line --update"
	echo "  $0 --update_java_only"
	echo "  $0 --ip_set"
	echo "  $0 --ip_set_v6"
	echo "  $0 --prevent_openvpn"
	exit 1
}

_off_line="false"
_update="false"
_ip_set="false"
_ip_set_v6="false"
_prevent_openvpn="false"
for i in "$@"
do
case $i in
	--off_line)
		_off_line="true"
		shift
		;;			

	--update)
		_update="true"
		shift
		;;

	--update_java_only)
		fn_gateway_config
		fn_check_result $? "fn_gateway_config"
		fn_delete_install_file
		systemctl restart connect-gateway
		systemctl restart connect-gateway-check
		exit 0
		;;

	--ip_set)
		_ip_set="true"
		shift
		;;

	--ip_set_v6)
		_ip_set="true"
		_ip_set_v6="true"
		shift
		;;

	--prevent_openvpn)
		_prevent_openvpn="true"
		shift
		;;

	--help)
		fn_help
		;;		
	*)
		fn_help      # unknown option
		;;
esac
done

fn_wizard
