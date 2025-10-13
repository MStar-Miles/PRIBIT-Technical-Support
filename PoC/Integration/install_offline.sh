#!/bin/bash
_PRODUCT_NAME="PRIBIT Connect Controller"
_NAME=ctrl
_OBJ_NAME="controller"
_FILE_SQL="controller_noData.sql"
_BACKUP_SQL="/opt/connect/controller/db_backup/DB_RISK_ONPREMISE.sql"

_PATH_PCCC=/usr/local/pribit/connect
_PATH_PACKAGE=${_PATH_PCCC}/services

_SERVICE_CTRL="connect-controller"
_SERVICE_CTRL_WEB="connect-controller-web"
_SERVICE_CTRL_CHECK="connect-controller-check"
_SERVICE_CTRL_API="connect-controller-api"

_OS_DESCRIPTION=$(lsb_release -d | awk '{ print $2, $3, $4 }')
_OS_RELEASE_VERSION=$(lsb_release -r | awk '{ print $2 }')
_OS_RELEASE_FULL_VERSION=$(lsb_release -d | awk '{ print $3 }')
_OS_POSSIBLE_VERSION="20.04"

_THIRDPARTY_NGINX_VERSION="1.26.3"
_THIRDPARTY_MARIADB_VERSION="10.6.21"
if [ "$_OS_RELEASE_VERSION" = "24.04" ]; then
    _THIRDPARTY_MARIADB_VERSION="10.11.11"
    export DEBIAN_FRONTEND=noninteractive
fi
_THIRDPARTY_MARIADB_MAJOR_VERSION=${_THIRDPARTY_MARIADB_VERSION%.*}
_THIRDPARTY_REDIS_VERSION="7.4.2"
_THIRDPARTY_OPENSSL_VERSION="3.0.16"

_ZTNA_DB_SCHEMA="DB_PGZT"

_INSTALL_LOG=/opt/connect/logs/connect-controller-install.log

function fnPrintLine(){
  echo "=========================================================================================" | tee -a $_INSTALL_LOG
}

function fnLogLine(){
  echo "=========================================================================================" >> $_INSTALL_LOG 2>&1
}

function fnPrintText(){
  local _MSG_TEXT=$1
  echo "$(date +'%Y-%m-%d %H:%M:%S') | ${_MSG_TEXT}" | tee -a $_INSTALL_LOG
}

function fnLogText(){
  local _MSG_TEXT=$1
  echo "$(date +'%Y-%m-%d %H:%M:%S') | ${_MSG_TEXT}" >> $_INSTALL_LOG 2>&1
}

function fnShowProgress() {
  local pid=$1
  local progressMsg=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local charwidth=${#spin}

  while kill -0 $pid 2>/dev/null; do
    for ((i=0; i<$charwidth; i++)); do
      echo -ne "\r$(date +'%Y-%m-%d %H:%M:%S') | ${progressMsg} Progress...[${spin:$i:1}]                      "
      sleep 0.1
    done
  done
  echo -ne "\r$(date +'%Y-%m-%d %H:%M:%S') | ${progressMsg}                                    \n"
}

function fnVersionCheck(){
  if [[ $1 == $2 ]]
  then
    echo "$no"
    return 0
  fi

  local IFS=.
  local i ver1=($1) ver2=($2)
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=${#ver2[@]}; i<${#ver1[@]}; i++))
  do
    ver2[i]=0
  done

  for ((i=0; i<${#ver1[@]}; i++))
  do
    if ((10#${ver1[i]} > 10#${ver2[i]}))
    then
      echo "no"
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      echo "yes"
      return 2
    fi
  done
  echo "no"
  return 0
}

function fnHostnameSetting(){
  _HOSTNAME=$(hostname)
    fnPrintText "hostname change"
    fnLogLine
  if [[ "${_HOSTNAME}" =~ "${_SERVICE_CTRL}" ]]; then
    fnPrintText "hostname already ${_HOSTNAME}"
    fnPrintLine
  else
    hostnamectl set-hostname ${_SERVICE_CTRL}
    fnPrintText "hostname change to ${_SERVICE_CTRL} SUCCESS"
    fnPrintLine
  fi
}

function fnPauseExit(){
  echo "Please try again from the beginning."
  echo
  read -s -n 1 -p "Press any Key to Exit..."
  echo
  exit 1
}

function fnExceedCount(){
  EXCEED_CNT=$1
  if [ $EXCEED_CNT -gt 5 ]; then
    fnPrintLine
    echo "You have exceeded the number of times you can input."
    fnPauseExit
  fi
}

function fnCompareInputs(){
  local COMPARE_TARGET=$1
  local FIRST_INPUT=$2
  local SECOND_INPUT=$3
  local COMPARE_TARGET_CNT=1

  while true
  do
    if [ "$FIRST_INPUT" != "$SECOND_INPUT" ]; then
      if [ $COMPARE_TARGET == "ip_compare" ];then
        echo "Sorry, IP Address do not match.($COMPARE_TARGET_CNT/5)"
      else
        echo "Sorry, passwords do not match.($COMPARE_TARGET_CNT/5)"
      fi
      ((COMPARE_TARGET_CNT++))
      fnExceedCount $COMPARE_TARGET_CNT
      echo
      if [ $COMPARE_TARGET == "ip_compare" ];then
        echo -n "Re-enter Allowed IP for ${_PRODUCT_NAME} : "
        read SECOND_INPUT
      else
        echo -n "Re-enter DBMS $COMPARE_TARGET new password: "
        stty -echo
        read SECOND_INPUT
        stty echo
      fi
      echo
    else
      break
    fi
  done
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

function fnValidatePW(){
  local TARGET_USR=$1
  local TARGET_PW=$2

  local PW_LEN="${#TARGET_PW}"
  local INPUT_CNT=1

  while true
  do
    if [ -z "$TARGET_PW" ]; then
      echo "Sorry, you can't use an empty password here.($INPUT_CNT/5)"
      ((INPUT_CNT++))
      fnExceedCount $INPUT_CNT
      echo
      echo -n "Enter DBMS $TARGET_USR new password: "
      stty -echo
      read TARGET_PW
      stty echo
      echo
      PW_LEN="${#TARGET_PW}"
    else
      if [[ "$TARGET_PW" == *" "* ]]; then
        echo "Password cannot contain spaces.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fnExceedCount $INPUT_CNT
        echo
        echo -n "Enter DBMS $TARGET_USR new password: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif echo "$TARGET_PW" | grep -E '(.)\1\1' > /dev/null; then
        echo "Password cannot contain 3 or more consecutive repeated characters.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fnExceedCount $INPUT_CNT
        echo
        echo -n "Enter DBMS $TARGET_USR new password: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif check_username_substring "$TARGET_USR" "$TARGET_PW"; then
        echo "Password cannot contain 4 or more consecutive characters from username.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fnExceedCount $INPUT_CNT
        echo
        echo -n "Enter DBMS $TARGET_USR new password: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      elif check_keyboard_sequence "$TARGET_PW"; then
        echo "Password cannot contain 4 or more consecutive keyboard characters.($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fnExceedCount $INPUT_CNT
        echo
        echo -n "Enter DBMS $TARGET_USR new password: "
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
          fnExceedCount $INPUT_CNT
          echo
          echo -n "Enter DBMS $TARGET_USR new password: "
          stty -echo
          read TARGET_PW
          stty echo
          echo
          PW_LEN="${#TARGET_PW}"
        fi
      else
        echo "Password must be greater then 8 and lower then 17 characters!($INPUT_CNT/5)"
        ((INPUT_CNT++))
        fnExceedCount $INPUT_CNT
        echo
        echo -n "Enter DBMS $TARGET_USR new password: "
        stty -echo
        read TARGET_PW
        stty echo
        echo
        PW_LEN="${#TARGET_PW}"
      fi
    fi
  done

  if [ "$TARGET_USR" == "root" ]; then
    DB_ROOT_PW=$TARGET_PW
  else
    PRIBIT_USER_PW=$TARGET_PW
  fi
}

function fnValidateUsername(){
  local TARGET_USERNAME=$1
  local USERNAME_LEN="${#TARGET_USERNAME}"
  local INPUT_USERNAME_CNT=1

  while true
  do
    if [ -z $TARGET_USERNAME ]; then
      echo "Sorry, you can't use an empty user name here.($INPUT_USERNAME_CNT/5)"
      ((INPUT_USERNAME_CNT++))
      fnExceedCount $INPUT_USERNAME_CNT
      echo
      echo -n "Create database User : "
      read TARGET_USERNAME
      USERNAME_LEN="${#TARGET_USERNAME}"
    else
      if [[ "$TARGET_USERNAME" == *" "* ]]; then
        echo "Sorry, username cannot contain spaces.($INPUT_USERNAME_CNT/5)"
        ((INPUT_USERNAME_CNT++))
        fnExceedCount $INPUT_USERNAME_CNT
        echo
        echo -n "Create database User : "
        read TARGET_USERNAME
        USERNAME_LEN="${#TARGET_USERNAME}"
      elif [ $USERNAME_LEN -gt 3 ]; then
        if [ $TARGET_USERNAME == "root" -o $TARGET_USERNAME == "mysql" -o $TARGET_USERNAME == "mariadb" -o $TARGET_USERNAME == "mariadb.sys" ]; then
          echo "Sorry, you can't use $PRIBIT_USER ($INPUT_USERNAME_CNT/5)"
          ((INPUT_USERNAME_CNT++))
          fnExceedCount $INPUT_USERNAME_CNT
          echo
          echo -n "Create database User : "
          read TARGET_USERNAME
          USERNAME_LEN="${#TARGET_USERNAME}"
        else
          break
        fi
      else
        echo "new user name must be of at least 3 characters!($INPUT_USERNAME_CNT/5)"
        ((INPUT_USERNAME_CNT++))
        fnExceedCount $INPUT_USERNAME_CNT
        echo
        echo -n "Create database User : "
        read TARGET_USERNAME
        USERNAME_LEN="${#TARGET_USERNAME}"
      fi
    fi
  done

  PRIBIT_USER=$TARGET_USERNAME
}

function fnDbmsInputSetPassword(){
  echo -n "Enter DBMS root new password: "
  stty -echo
  IFS= read -r DB_ROOT_PW
  stty echo
  echo
  fnValidatePW "root" "$DB_ROOT_PW"

  echo -n "Re-enter DBMS root new password: "
  stty -echo
  IFS= read -r DB_ROOT_CHK_PW
  stty echo
  echo
  fnCompareInputs "root" "$DB_ROOT_PW" "$DB_ROOT_CHK_PW"
}

function fnDBRiskInputUserSetting(){
  echo "========================================================================================="
  echo -n "Create database User : "
  IFS= read -r PRIBIT_USER
  stty echo
  echo
  fnValidateUsername "$PRIBIT_USER"

  echo -n "Enter $PRIBIT_USER new password: "
  stty -echo
  read PRIBIT_USER_PW
  stty echo
  echo
  fnValidatePW "$PRIBIT_USER" "$PRIBIT_USER_PW"

  echo -n "Re-enter $PRIBIT_USER new password: "
  stty -echo
  read PRIBIT_USER_CHK_PW
  stty echo
  echo
  fnCompareInputs "$PRIBIT_USER" "$PRIBIT_USER_PW" "$PRIBIT_USER_CHK_PW"
  echo "========================================================================================="
}

function fnCheckIP(){
  local TARGET_IP=$1
  local VALIDE_IP_STAT=1
  local IP_INPUT_CNT=1
  while true
  do
    if [[ $TARGET_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
      OIFS=$IFS
      IFS='.'
      local ARR_IP=($TARGET_IP)
      IFS=$OIFS
      [[ ${ARR_IP[0]} -le 255 && ${ARR_IP[1]} -le 255 && ${ARR_IP[2]} -le 255 && ${ARR_IP[3]} -le 255 ]]
      VALIDE_IP_STAT=$?
      if [[ $VALIDE_IP_STAT -eq 0 ]]; then
#        if [[ ${ARR_IP[3]} -eq 0 || ${ARR_IP[3]} -eq 1 || ${ARR_IP[3]} -eq 255 ]]; then
#          echo "Sorry, Restricted IP Address.($IP_INPUT_CNT/5)"
#          ((IP_INPUT_CNT++))
#          fnExceedCount $IP_INPUT_CNT
#          echo
#          echo -n "Enter Allowed IP for ${_PRODUCT_NAME} : "
#          read TARGET_IP
#        else
#          break
#        fi
        break
      else
        echo "Sorry, Invalid IP address.($IP_INPUT_CNT/5)"
        ((IP_INPUT_CNT++))
        fnExceedCount $IP_INPUT_CNT
        echo
        echo -n "Enter Allowed IP for ${_PRODUCT_NAME} : "
        read TARGET_IP
      fi
    else
      if [ -z $TARGET_IP ]; then
        echo "Sorry, you can't use an empty IP Address here.($IP_INPUT_CNT/5)"
        ((IP_INPUT_CNT++))
        fnExceedCount $IP_INPUT_CNT
        echo
        echo -n "Enter Allowed IP for ${_PRODUCT_NAME} : "
        read TARGET_IP
      else
        if [ $TARGET_IP == "localhost" -o $TARGET_IP == "LOCALHOST" ]; then
          echo "Sorry, Restricted IP Address.($IP_INPUT_CNT/5)"
        else
          echo "Sorry, Invalid IP address.($IP_INPUT_CNT/5)"
        fi
        ((IP_INPUT_CNT++))
        fnExceedCount $IP_INPUT_CNT
        echo
        echo -n "Enter Allowed IP for ${_PRODUCT_NAME} : "
        read TARGET_IP
      fi
    fi
  done
  ALLOWED_IP=$TARGET_IP
}

function fnConnectControllerRestrictedIP(){
  echo -n "Enter Allowed IP for ${_PRODUCT_NAME} : "
  read ALLOWED_IP
  fnCheckIP $ALLOWED_IP

  echo -n "Re-enter Allowed IP for ${_PRODUCT_NAME} : "
  read ALLOWED_RE_IP
  fnCompareInputs "ip_compare" "$ALLOWED_IP" "$ALLOWED_RE_IP"
  echo "========================================================================================="
}

function fnMariadbConfiguraionExpect(){
  fnPrintText "mysql_secure_installation"
  fnLogLine
  mysql --user=root <<_EOF_
    INSTALL SONAME 'auth_ed25519';
    ALTER USER 'root'@'localhost' IDENTIFIED VIA ed25519 USING PASSWORD('$DB_ROOT_PW');
    CREATE USER 'root'@'127.0.0.1' IDENTIFIED VIA ed25519 USING PASSWORD('$DB_ROOT_PW');
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1';
    FLUSH PRIVILEGES;
_EOF_

  sleep 1
  SECURE_SETTING=$(expect -c "
    set timeout 3
    spawn mysql_secure_installation
    expect \"Enter current password for root (enter for none):\"
    send \"$DB_ROOT_PW\r\"
    expect \"Switch to unix_socket authentication\"
    send \"n\r\"
    expect \"Change the root password?\"
    send \"n\r\"
    expect \"Remove anonymous users?\"
    send \"Y\r\"
    expect \"Disallow root login remotely?\"
    send \"Y\r\"
    expect \"Remove test database and access to it?\"
    send \"Y\r\"
    expect \"Reload privilege tables now?\"
    send \"Y\r\"
    expect eof")

  echo "$SECURE_SETTING" >> $_INSTALL_LOG 2>&1
  sleep 1
  fnLogLine
  fnPrintText "mysql_secure_installation SUCCESS"
  fnPrintLine
}

function fnDbRiskSetting(){
  fnPrintText "${_PRODUCT_NAME} DataBase Setting"
  fnLogLine
  sed -i '1d' ${_PATH_PACKAGE}/${_NAME}/$_FILE_SQL
  sed -i "1 i\CREATE DATABASE $_ZTNA_DB_SCHEMA DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" ${_PATH_PACKAGE}/${_NAME}/$_FILE_SQL
  sed -i '2d' ${_PATH_PACKAGE}/${_NAME}/$_FILE_SQL
  sed -i "2 i\USE $_ZTNA_DB_SCHEMA;" ${_PATH_PACKAGE}/${_NAME}/$_FILE_SQL

  mysql -h localhost -u root -p$DB_ROOT_PW < ${_PATH_PACKAGE}/${_NAME}/$_FILE_SQL
  sleep 1
  mysql -h localhost -u root -p$DB_ROOT_PW <<_EOF_
    CREATE OR REPLACE USER '$PRIBIT_USER'@'localhost' IDENTIFIED VIA ed25519 USING PASSWORD('$PRIBIT_USER_PW');
    CREATE OR REPLACE USER '$PRIBIT_USER'@'127.0.0.1' IDENTIFIED VIA ed25519 USING PASSWORD('$PRIBIT_USER_PW');
    GRANT ALL PRIVILEGES ON $_ZTNA_DB_SCHEMA.* TO '$PRIBIT_USER'@'localhost';
    GRANT ALL PRIVILEGES ON $_ZTNA_DB_SCHEMA.* TO '$PRIBIT_USER'@'127.0.0.1';
    FLUSH PRIVILEGES;
_EOF_

  fnPrintText "${_PRODUCT_NAME} DataBase Setting SUCCESS"
  fnPrintLine
}

function fnDbRiskUpgradeSetting(){
  fnPrintText "${_PRODUCT_NAME} DataBase Setting"
  fnLogLine
  sed -i '1d' ${_PATH_PACKAGE}/${_NAME}/controller_upgrade.sql
  sed -i "1 i\USE $_ZTNA_DB_SCHEMA;" ${_PATH_PACKAGE}/${_NAME}/controller_upgrade.sql
  mysql -h localhost -u root -p$DB_ROOT_PW < ${_PATH_PACKAGE}/${_NAME}/controller_upgrade.sql
  sleep 1
  mysql -h localhost -u root -p$DB_ROOT_PW <<_EOF_
    INSTALL SONAME 'auth_ed25519';
    ALTER USER 'root'@'localhost' IDENTIFIED VIA ed25519 USING PASSWORD('$DB_ROOT_PW');
    CREATE OR REPLACE USER 'root'@'127.0.0.1' IDENTIFIED VIA ed25519 USING PASSWORD('$DB_ROOT_PW');
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1';
    CREATE OR REPLACE USER '$PRIBIT_USER'@'localhost' IDENTIFIED VIA ed25519 USING PASSWORD('$PRIBIT_USER_PW');
    CREATE OR REPLACE USER '$PRIBIT_USER'@'127.0.0.1' IDENTIFIED VIA ed25519 USING PASSWORD('$PRIBIT_USER_PW');
    GRANT ALL PRIVILEGES ON $_ZTNA_DB_SCHEMA.* TO '$PRIBIT_USER'@'localhost';
    GRANT ALL PRIVILEGES ON $_ZTNA_DB_SCHEMA.* TO '$PRIBIT_USER'@'127.0.0.1';
    FLUSH PRIVILEGES;
_EOF_

  fnLogLine
  fnPrintText "${_PRODUCT_NAME} DataBase Setting SUCCESS"
  fnPrintLine
}

function fnAddMariadbRepository(){
  fnPrintText "mariadb add apt repository Setting"
  fnLogLine
  fnPrintText "OFF-LINE mode do not need add mariadb apt repository Setting"
  fnPrintLine
}

function fnDefaultDbSchema(){
  if [ -f "/opt/connect/controller/properties/authenticate.properties" ]; then
      _ZTNA_DB_SCHEMA=$(java -jar /opt/connect/controller/util/controller-util-1.0.jar dbSchema | awk '{print $3}')
  fi
}

function fnCheckService(){
  fnPrintText "check service"
  fnLogLine

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "${_SERVICE_CTRL}.service")
  if [ ! -z "${_IS_RUNNING}" ]; then
    fnPrintText "stop ${_SERVICE_CTRL} services"
    systemctl stop ${_SERVICE_CTRL}.service
    systemctl disable ${_SERVICE_CTRL}.service >> $_INSTALL_LOG 2>&1
    sleep 1
    rm -f /etc/systemd/system/${_SERVICE_CTRL}.service
    systemctl daemon-reload
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "${_SERVICE_CTRL_CHECK}")
  if [ ! -z "${_IS_RUNNING}" ]; then
    fnPrintText "stop ${_SERVICE_CTRL_CHECK} services"
    systemctl stop ${_SERVICE_CTRL_CHECK}.service
    systemctl disable ${_SERVICE_CTRL_CHECK}.service >> $_INSTALL_LOG 2>&1
    sleep 1
    rm -f /etc/systemd/system/${_SERVICE_CTRL_CHECK}.service
    systemctl daemon-reload
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "${_SERVICE_CTRL_WEB}")
  if [ ! -z "${_IS_RUNNING}" ]; then
    fnPrintText "stop ${_SERVICE_CTRL_WEB} services"
    systemctl stop ${_SERVICE_CTRL_WEB}.service
    systemctl disable ${_SERVICE_CTRL_WEB}.service >> $_INSTALL_LOG 2>&1
    sleep 1
    rm -f /etc/systemd/system/${_SERVICE_CTRL_WEB}.service
    systemctl daemon-reload
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "${_SERVICE_CTRL_API}")
  if [ ! -z "${_IS_RUNNING}" ]; then
    fnPrintText "stop ${_SERVICE_CTRL_API} services"
    systemctl stop ${_SERVICE_CTRL_API}.service
    systemctl disable ${_SERVICE_CTRL_API}.service >> $_INSTALL_LOG 2>&1
    sleep 1
    rm -f /etc/systemd/system/${_SERVICE_CTRL_API}.service
    systemctl daemon-reload
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "tomcat9")
  if [ ! -z "${_IS_RUNNING}" ]; then
    fnPrintText "stop tomcat9 services"
    systemctl stop tomcat9.service
    systemctl disable tomcat9.service >> $_INSTALL_LOG 2>&1
    fnPrintText "uninstall tomcat9"
    apt-get remove -y --purge tomcat9 tomcat9-common >> $_INSTALL_LOG 2>&1
    apt-get autoremove -y >> $_INSTALL_LOG 2>&1
    apt-get autoclean >> $_INSTALL_LOG 2>&1
    rm -rf /var/lib/tomcat9
    rm -f /etc/systemd/system/tomcat9.service
    rm -rf /var/cache/tomcat9
    systemctl daemon-reload
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "nginx")
  if [ ! -z "${_IS_RUNNING}" ]; then
    _NGINX_EXISTING_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}')
    _NGINX_VERSION_CHECK_RESULT=$(fnVersionCheck $_NGINX_EXISTING_VERSION $_THIRDPARTY_NGINX_VERSION)
    if [ "${_NGINX_VERSION_CHECK_RESULT}" == "yes" ]; then
      fnPrintText "stop nginx services"
      systemctl stop nginx.service
      systemctl disable nginx.service >> $_INSTALL_LOG 2>&1
      fnPrintText "uninstall nginx"
      apt-get remove -y --purge nginx nginx-common nginx-core >> $_INSTALL_LOG 2>&1
      apt-get autoremove -y >> $_INSTALL_LOG 2>&1
      apt-get autoclean >> $_INSTALL_LOG 2>&1
      rm -rf /var/log/nginx
      rm -rf /usr/sbin/nginx
      rm -rf /usr/share/nginx
      rm -rf /etc/nginx
      rm -f /etc/systemd/system/nginx.service
      find / -type f -name nginx.pid 2>/dev/null | xargs rm -f
      systemctl daemon-reload
    fi
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "redis-server")
  if [ ! -z "${_IS_RUNNING}" ]; then
    _REDIS_EXISTING_VERSION=$(redis-cli --version | awk '{ print $2 }')
    _REDIS_VERSION_CHECK_RESULT=$(fnVersionCheck $_REDIS_EXISTING_VERSION $_THIRDPARTY_REDIS_VERSION)
    if [ "${_REDIS_VERSION_CHECK_RESULT}" == "yes" ]; then
      fnPrintText "stop redis-server services"
      systemctl stop redis-server.service
      systemctl disable redis-server.service >> $_INSTALL_LOG 2>&1
      fnPrintText "uninstall redis-server"
      apt-get remove -y --purge redis-server redis-tools >> $_INSTALL_LOG 2>&1
      apt-get autoremove -y >> $_INSTALL_LOG 2>&1
      apt-get autoclean >> $_INSTALL_LOG 2>&1
      rm -rf /opt/thirdparty/redis
      find / -type f -name redis-server.service 2>/dev/null | xargs rm -f
      systemctl daemon-reload
    fi
  fi

  _IS_RUNNING=$(systemctl list-units --all -t service --full --no-legend | grep "mariadb")
  if [ ! -z "${_IS_RUNNING}" ]; then
    _MARIADB_EXISTING_VERSION=$(mariadb --version | awk '{split($5,v,"-"); print v[1] }')
    _MARIADB_VERSION_CHECK_RESULT=$(fnVersionCheck $_MARIADB_EXISTING_VERSION $_THIRDPARTY_MARIADB_VERSION)
    if [ "${_MARIADB_VERSION_CHECK_RESULT}" == "yes" ]; then
      {
        fnLogText "DBMS Backup"
        mkdir -p /opt/connect/controller/db_backup/
        if [ -e "${_BACKUP_SQL}" ]; then
          mv ${_BACKUP_SQL} ${_BACKUP_SQL}.$(date +'%Y%m%d_%H_%M_%S').bak
        fi
        mysqldump -uroot -p$DB_ROOT_PW --opt --single-transaction --master-data=2 -q --add-drop-database --databases $_ZTNA_DB_SCHEMA > ${_BACKUP_SQL}
        sed -i 's/DEFINER=[^*]*\*/\*/g' ${_BACKUP_SQL}
        sleep 1
      } &
      _BACKUP_PID=$!
      fnShowProgress $_BACKUP_PID "DBMS Backup"
      fnPrintText "stop mariadb services"
      systemctl stop mariadb.service
      systemctl disable mariadb.service >> $_INSTALL_LOG 2>&1
      sleep 1
      rm -f /etc/systemd/system/mariadb.service
      systemctl daemon-reload
      sleep 1
      fnPrintText "uninstall mariadb-backup mariadb-server mariadb-client"
      if [ "$_OS_RELEASE_VERSION" = "24.04" ]; then
        dpkg --purge mariadb-backup >> $_INSTALL_LOG 2>&1
        apt autoremove -y mariadb-server mariadb-client mariadb-common >> $_INSTALL_LOG 2>&1
        DEBIAN_FRONTEND=noninteractive dpkg --purge mariadb-server >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-server-core >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-client >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-client-core >> $_INSTALL_LOG 2>&1
        dpkg --purge libmariadb3 >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-common >> $_INSTALL_LOG 2>&1
      else
        apt autoremove -y mariadb-backup mariadb-server mariadb-client mariadb-common >> $_INSTALL_LOG 2>&1
        echo mariadb-server-10.6 mariadb-server-10.6/postrm_remove_databases boolean false | debconf-set-selections >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-server-10.6 >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-client-10.6 >> $_INSTALL_LOG 2>&1
        dpkg --purge mariadb-common >> $_INSTALL_LOG 2>&1
        dpkg --purge libdbd-mariadb-perl >> $_INSTALL_LOG 2>&1
      fi
      apt-get install -f -y >> $_INSTALL_LOG 2>&1
      dpkg --configure -a >> $_INSTALL_LOG 2>&1
      apt-get install -f -y >> $_INSTALL_LOG 2>&1
    fi
  fi

  _EXISTS_JRE_MAJOR_VERSION=$(dpkg -l | grep "jre" | awk 'NR==1{split($3,n,"+");split(n[1],v,"."); print v[1]}')
  if [ "${_EXISTS_JRE_MAJOR_VERSION}" == "11" ]; then
    fnPrintText "uninstall openjdk-11-jre"
    dpkg --purge openjdk-11-jre >> $_INSTALL_LOG 2>&1
    apt-get install -f -y >> $_INSTALL_LOG 2>&1
    dpkg --configure -a >> $_INSTALL_LOG 2>&1
    apt-get install -f -y >> $_INSTALL_LOG 2>&1
  fi
  fnPrintText "check service SUCCESS"
  fnPrintLine
}

function fnAddControllerService(){
  fnPrintText "systemd add connect controller service"
  fnLogLine
  /usr/bin/cat << EOF > /etc/systemd/system/${_SERVICE_CTRL}.service
[Unit]
Description=${_PRODUCT_NAME} RPC Application Service
After=network.target

[Install]
WantedBy=multi-user.target
[Service]
Type=simple
WorkingDirectory=/opt/connect/controller

ExecStart=/usr/bin/java -server -Dpgct=connect-controller -Dpgct.home=/opt/connect/controller -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms2048m -Xmx3072m -jar /opt/connect/controller/rpc/controller-rpc-1.0.jar
ExecStartPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_startlog
ExecStopPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_stoplog

Restart=on-failure
RestartSec=20
EOF
  chmod 0644 /etc/systemd/system/${_SERVICE_CTRL}.service

  /usr/bin/cat << EOF > /etc/systemd/system/${_SERVICE_CTRL_CHECK}.service
[Unit]
Description=${_PRODUCT_NAME} Check Application Service
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
WorkingDirectory=/opt/connect/controller

ExecStart=/usr/bin/java -Djdk.lang.Process.launchMechanism=vfork -jar /opt/connect/controller/check/controller-check-1.0.jar
ExecStartPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_check_startlog
ExecStopPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_check_stoplog
#Restart=on-failure
RestartSec=20
EOF
  chmod 0644 /etc/systemd/system/${_SERVICE_CTRL_CHECK}.service

  /usr/bin/cat << EOF > /etc/systemd/system/${_SERVICE_CTRL_WEB}.service
[Unit]
Description=${_PRODUCT_NAME} Web Application Service
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
WorkingDirectory=/opt/connect/controller

ExecStart=/usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/web/controller-web-1.0.war
ExecStartPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_web_startlog
ExecStopPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_web_stoplog

Restart=on-failure
RestartSec=30
EOF
  chmod 0644 /etc/systemd/system/${_SERVICE_CTRL_WEB}.service

  /usr/bin/cat << EOF > /etc/systemd/system/${_SERVICE_CTRL_API}.service
[Unit]
Description=${_PRODUCT_NAME} API Application Service
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
WorkingDirectory=/opt/connect/controller

ExecStart=/usr/bin/java -server -Dfile.encoding=UTF-8 -Djdk.lang.Process.launchMechanism=vfork -Xms512M -Xmx1024M -XX:+UseParallelGC -jar /opt/connect/controller/api/controller-api-1.0.jar
ExecStartPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_api_startlog
ExecStopPost=/opt/connect/controller/thirdparty-conf-set --connect_controller_api_stoplog

Restart=on-failure
RestartSec=30
EOF
  chmod 0644 /etc/systemd/system/${_SERVICE_CTRL_API}.service

  mkdir -p /opt/connect/controller/properties/

  systemctl daemon-reload
  systemctl enable ${_SERVICE_CTRL}.service >> $_INSTALL_LOG 2>&1
  systemctl enable ${_SERVICE_CTRL_CHECK}.service >> $_INSTALL_LOG 2>&1
  systemctl enable ${_SERVICE_CTRL_WEB}.service >> $_INSTALL_LOG 2>&1
  systemctl enable ${_SERVICE_CTRL_API}.service >> $_INSTALL_LOG 2>&1

  fnLogLine
  fnPrintText "systemd add connect controller service SUCCESS"
  fnPrintLine
}

function fnNginxCompileBuild(){
  _IS_RUNNING_NGINX=$(systemctl list-units --all -t service --full --no-legend | grep "nginx.service")
  fnPrintText "nginx build"
  fnLogLine
  if [ -z "${_IS_RUNNING_NGINX}" ]; then
    {
      if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
        apt-get remove -y libssl-dev >> $_INSTALL_LOG 2>&1
      fi
      cd ${_PATH_PACKAGE}/thirdparty-packages/nginx
      fnLogText "decompression nginx-${_THIRDPARTY_NGINX_VERSION}.tar.gz"
      fnLogLine
      tar -zxvf headers-more-nginx-module-0.38.tar.gz >> $_INSTALL_LOG 2>&1
      sleep 1
      tar -zxvf nginx-${_THIRDPARTY_NGINX_VERSION}.tar.gz >> $_INSTALL_LOG 2>&1
      sleep 1
      cd nginx-${_THIRDPARTY_NGINX_VERSION}
      fnLogLine
      fnLogText "nginx configure"
      fnLogLine
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
      --with-http_realip_module \
      --with-stream_realip_module \
      --with-http_secure_link_module \
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
      --add-module=../headers-more-nginx-module-0.38 >> $_INSTALL_LOG 2>&1
      fnCheckMsgResult $? "nginx configure"
      sleep 1
      fnLogLine
      make >> $_INSTALL_LOG 2>&1
      fnCheckMsgResult $? "nginx make"
      sleep 1
      fnLogLine
      fnLogText "nginx make install"
      fnLogLine
      make install >> $_INSTALL_LOG 2>&1
      fnCheckMsgResult $? "nginx make install"
      sleep 1
      rm -f /etc/nginx/*
      cp -f ${_PATH_PACKAGE}/nginx/400.html /usr/share/nginx/html/400.html
      cp -f ${_PATH_PACKAGE}/nginx/error.html /usr/share/nginx/html/error.html
      cp -f ${_PATH_PACKAGE}/nginx/50x.html /usr/share/nginx/html/50x.html
      #unlink /etc/nginx/sites-enabled/default
      chmod 644 ${_PATH_PACKAGE}/nginx/nginx.service
      cp -f ${_PATH_PACKAGE}/nginx/nginx.service /etc/systemd/system/

      systemctl daemon-reload
      systemctl enable nginx.service >> $_INSTALL_LOG 2>&1
    } &
    _NGINX_BUILD_PID=$!
    fnShowProgress $_NGINX_BUILD_PID "nginx configure make install"
    wait $_BACKUP_PID
    fnLogLine
    fnPrintText "nginx make install build SUCCESS"
    fnPrintLine
  else
    fnPrintText "nginx already build v${_THIRDPARTY_NGINX_VERSION}"
    fnPrintLine
  fi
}

function fnCheckMsgResult(){
  local _CHECK_RESULT=$1
  local _EXIT_MSG=$2
  if [ ${_CHECK_RESULT} -ne 0 ]; then
    fnLogLine
    fnPrintText "${_EXIT_MSG} FAILED"
    fnPrintLine
    echo "$(date +'%Y-%m-%d %H:%M:%S') | check log file path '${_INSTALL_LOG}'"
    exit 1
  fi
}

function fnCheckResult(){
  local _RESULT=$1
  local _CHECK_PKG=$2

  if [ ${_RESULT} -ne 0 ]; then
    fnLogLine
    if [ "${_CHECK_PKG}" = "libssl-dev" ]; then
      fnPrintText "${_CHECK_PKG} already installed"
      fnPrintLine
    else
      fnPrintText "${_CHECK_PKG} install FAILED"
      fnPrintLine
      echo "$(date +'%Y-%m-%d %H:%M:%S') | check log file path '${_INSTALL_LOG}'"
      exit 1
    fi
  else
    fnLogLine
    fnPrintText "${_CHECK_PKG} install SUCCESS"
    fnPrintLine
  fi
}

function fnInstallPkg(){
  _PKGS=$1
  _RET=$(dpkg -l | grep ${_PKGS} | awk '{print $2}')

  rm -f /var/lib/dpkg/lock-frontend
  rm -f /var/lib/dpkg/lock
  rm -f /var/lib/apt/lists/lock
  find /var/cache/apt/archives -type f -exec rm {} +
  cp ${_PATH_PACKAGE}/thirdparty-packages/${_PKGS}/*.deb /var/cache/apt/archives/
  cd /var/cache/apt/archives/
  if [ -z "${_RET}" ]; then
    fnPrintText "${_PKGS} install"
    fnLogLine
    apt-get install -y --no-download ./*.deb >> $_INSTALL_LOG 2>&1 &
    fnShowProgress $! "${_PKGS} installation"
    wait $!
    fnCheckResult $? ${_PKGS}
    if [ "${_PKGS}" == "openjdk-17-jre" ]; then
      _EXISTS_CHECK_JRE11=$(dpkg -l | grep "openjdk-11-jre-headless:amd64" | awk '{print $2}')
      if [ ! -z "${_EXISTS_CHECK_JRE11}" ]; then
        dpkg --purge openjdk-11-jre-headless >> $_INSTALL_LOG 2>&1
      fi
    fi
  else
    if [ "${_PKGS}" == "expect" ]; then
      fnPrintText "${_PKGS} install"
      fnLogLine
      _EXISTS_CHECK_EXPECT=$(dpkg -l | grep " expect " | awk '{print $2}')
      if [ -z "${_EXISTS_CHECK_EXPECT}" ]; then
        apt-get install -y --no-download ./*.deb >> $_INSTALL_LOG 2>&1 &
        fnShowProgress $! "${_PKGS} installation"
        wait $!
        fnCheckResult $? ${_PKGS}
      else
        fnPrintText "${_PKGS} already installed."
        fnPrintLine
      fi
    elif [ "${_PKGS}" == "snmp" ]; then
      fnPrintText "${_PKGS} install"
      fnLogLine
      _EXISTS_CHECK_SNMP=$(dpkg -l | grep " snmp " | awk '{ print $2}')
      if [ -z "${_EXISTS_CHECK_SNMP}" ]; then
        apt-get install -y --no-download ./*.deb >> $_INSTALL_LOG 2>&1 &
        fnShowProgress $! "${_PKGS} installation"
        wait $!
        fnCheckResult $? ${_PKGS}
      else
        fnPrintText "${_PKGS} already installed."
        fnPrintLine
      fi
    else
      fnPrintText "${_PKGS} install"
      fnLogLine
      fnPrintText "${_PKGS} already installed."
      fnPrintLine
    fi
  fi
  find /var/cache/apt/archives -type f -exec rm {} +
}

function fnTimeSetting() {
  timedatectl set-timezone "Asia/Seoul"
  rdate -s time.bora.net
  fnPrintText "timezone is 'Asia/Seoul'"
  fnPrintText "time server is 'time.bora.net'"
  fnPrintLine
}

function fnInsertContentFile(){
  local _INSERT_LINE=$1
  local _INSERT_CONTENT=$2
  local _INSERT_FILE=$3
  local _CHECK_CONTENT=$(sed -n "${_INSERT_LINE}p" ${_INSERT_FILE} | grep "${_INSERT_CONTENT}")
  if [ -z "${_CHECK_CONTENT}" ]; then
    sed -i "${_INSERT_LINE}i${_INSERT_CONTENT}" ${_INSERT_FILE}
  fi
}

function fnRsyslogSetting() {
  fnPrintText "rsyslog setting"
  fnLogLine

  fnInsertContentFile "7" ":programname, isequal, \"java\" stop" /etc/rsyslog.conf
  fnInsertContentFile "8" ":programname, isequal, \"mariadbd\" stop" /etc/rsyslog.conf
  fnInsertContentFile "9" ":programname, isequal, \"startup.sh\" stop" /etc/rsyslog.conf
  fnInsertContentFile "10" ":programname, isequal, \"thirdparty-conf-set\" stop" /etc/rsyslog.conf
  fnInsertContentFile "11" ":programname, isequal, \"mariadb-server-10.6.postinst\" stop" /etc/rsyslog.conf
  fnInsertContentFile "12" ":programname, isequal, \"/etc/mysql/debian-start\" stop" /etc/rsyslog.conf
  fnInsertContentFile "13" ":msg, contains, \"MariaDB\" stop" /etc/rsyslog.conf
  fnInsertContentFile "14" ":msg, contains, \"mariadb\" stop" /etc/rsyslog.conf
  fnInsertContentFile "15" ":msg, contains, \"mysql\" stop" /etc/rsyslog.conf
  fnInsertContentFile "16" ":msg, contains, \"MyISAM\" stop" /etc/rsyslog.conf
  fnInsertContentFile "17" ":msg, contains, \"mysql\" stop" /etc/rsyslog.conf
  fnInsertContentFile "18" ":msg, contains, \"omcat9\" stop" /etc/rsyslog.conf
  fnInsertContentFile "19" ":msg, contains, \"tomcat\" stop" /etc/rsyslog.conf
  fnInsertContentFile "20" ":msg, contains, \"PRIBIT\" stop" /etc/rsyslog.conf
  fnInsertContentFile "21" ":msg, contains, \"pribit\" stop" /etc/rsyslog.conf
  fnInsertContentFile "22" ":msg, contains, \"NGINX\" stop" /etc/rsyslog.conf
  fnInsertContentFile "23" ":msg, contains, \"nginx\" stop" /etc/rsyslog.conf
  fnInsertContentFile "24" ":msg, contains, \"connect-controller\" stop" /etc/rsyslog.conf
  sed -i 's/#module(load="imudp")/module(load="imudp")/g' /etc/rsyslog.conf
  sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/g' /etc/rsyslog.conf
  sed -i 's/#module(load="imtcp")/module(load="imtcp")/g' /etc/rsyslog.conf
  sed -i 's/#input(type="imtcp" port="514")/input(type="imtcp" port="514")/g' /etc/rsyslog.conf

  fnInsertContentFile "4" ":msg, contains, \"MariaDB\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "5" ":msg, contains, \"mariadb\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "6" ":msg, contains, \"mysql\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "7" ":msg, contains, \"MyISAM\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "8" ":msg, contains, \"mysql\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "9" ":msg, contains, \"omcat9\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "10" ":msg, contains, \"tomcat\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "11" ":msg, contains, \"PRIBIT\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "12" ":msg, contains, \"pribit\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "13" ":msg, contains, \"NGINX\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "14" ":msg, contains, \"nginx\" stop" /etc/rsyslog.d/50-default.conf
  fnInsertContentFile "15" ":msg, contains, \"connect-controller\" stop" /etc/rsyslog.d/50-default.conf

  local _SYS_TIMESTAMP=$(date +'%Y-%m-%d_%H:%M:%S')
  cp /var/log/syslog /var/log/syslog-${_SYS_TIMESTAMP}.bak
  if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
    cp /var/log/auth.log /var/log/auth-${_SYS_TIMESTAMP}.bak
  fi
  cp /var/log/kern.log /var/log/kern-${_SYS_TIMESTAMP}.bak

  chmod +x ${_PATH_PACKAGE}/sys/pribit_encoder
  ${_PATH_PACKAGE}/sys/pribit_encoder /var/log/syslog-${_SYS_TIMESTAMP}.bak
  if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
    ${_PATH_PACKAGE}/sys/pribit_encoder /var/log/auth-${_SYS_TIMESTAMP}.bak
  fi
  ${_PATH_PACKAGE}/sys/pribit_encoder /var/log/kern-${_SYS_TIMESTAMP}.bak
  rm -f /var/log/syslog.bak
  if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
    rm -f /var/log/auth.bak
  fi
  rm -f /var/log/kern.bak

  systemctl restart rsyslog.service
  sleep 1
  cp /dev/null /var/log/syslog
  if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
    cp /dev/null /var/log/auth.log
  fi
  cp /dev/null /var/log/kern.log

  fnPrintText "rsyslog setting SUCCESS"
  fnPrintLine
}

function fnOpensslCompileBuild() {
  _OPENSSL_EXISTING_VERSION=$(openssl version | awk '{print $2}')
  _OPENSSL_VERSION_CHECK_RESULT=$(fnVersionCheck $_OPENSSL_EXISTING_VERSION $_THIRDPARTY_OPENSSL_VERSION)
  fnPrintText "openssl build"
  fnLogLine
  if [ "${_OPENSSL_VERSION_CHECK_RESULT}" == "yes" ]; then
    {
      if [ "$_OS_RELEASE_VERSION" = "24.04" ]; then
        dpkg --force-all -i ${_PATH_PACKAGE}/thirdparty-packages/bc/*.deb >> $_INSTALL_LOG 2>&1
        fnLogLine
      fi
      cd ${_PATH_PACKAGE}/thirdparty-packages/openssl || exit
      fnLogText "decompression openssl-${_THIRDPARTY_OPENSSL_VERSION}.tar.gz"
      fnLogLine
      sleep 1
      tar xvfz openssl-${_THIRDPARTY_OPENSSL_VERSION}.tar.gz >> $_INSTALL_LOG 2>&1
      cd openssl-${_THIRDPARTY_OPENSSL_VERSION} || exit
      sleep 1
      fnLogLine
      fnLogText "openssl config"
      fnLogLine
      ./config >> $_INSTALL_LOG 2>&1
      sleep 1
      fnLogLine
      _CPU_CORES=$(cat /proc/cpuinfo | grep cores | wc -l)
      _WEIGHTED=$(echo "$_CPU_CORES*0.2"|bc)
      let _OPTIMIZATION_CORES=${_CPU_CORES}+$(printf %.0f ${_WEIGHTED})
      make -j ${_OPTIMIZATION_CORES} >> $_INSTALL_LOG 2>&1
      fnCheckMsgResult $? "openssl make"
      sleep 1
      fnLogLine
      make install >> $_INSTALL_LOG 2>&1
      fnCheckMsgResult $? "openssl make install"
      sleep 1
      mv /usr/bin/openssl /usr/bin/openssl-"${_OPENSSL_EXISTING_VERSION}"
      ln -s /usr/local/bin/openssl /usr/bin/openssl
      sleep 1
      _CHECK_LD_LIB_PATH=$(grep -r "/usr/local/lib64" /etc/ld.so.conf.d/libc.conf | awk '{print}')
      if [ -z "$_CHECK_LD_LIB_PATH" ]; then
        echo "/usr/local/lib64" >> /etc/ld.so.conf.d/libc.conf
      fi
      sleep 1
      ldconfig
      sleep 1
      if [ "$_OS_RELEASE_VERSION" = "20.04" ]; then
        apt-get remove -y libssl-dev >> $_INSTALL_LOG 2>&1
      fi
      sleep 1
    } &
    _OPENSSL_BUILD_PID=$!
    fnShowProgress $_OPENSSL_BUILD_PID "openssl configure make install"
    wait $_OPENSSL_BUILD_PID
    fnLogLine
    fnPrintText "openssl build SUCCESS"
    fnPrintLine
  else
    fnPrintText "openssl already build v${_OPENSSL_EXISTING_VERSION}"
    fnPrintLine
  fi
}

function fnRemoveCompileLibraries(){
	apt-get -y purge make gcc build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev shc && apt-get -y autoremove
}

function fnRemoveInstallFiles() {
  fnPrintText "remove install files"
  fnLogLine
  rm -rf /usr/local/pribit/connect/services/ctrl
  rm -rf /usr/local/pribit/connect/services/mysql
  rm -rf /usr/local/pribit/connect/services/nginx
  rm -rf /usr/local/pribit/connect/services/sys
  rm -rf /usr/local/pribit/connect/services/thirdparty-packages

#  rm -f /usr/local/pribit/connect/services/ctrl/controller_noData.sql
#  rm -f /usr/local/pribit/connect/services/ctrl/controller-web.war
#  rm -f /usr/local/pribit/connect/services/ctrl/ctrl-service.conf
#  rm -f /usr/local/pribit/connect/services/ctrl/README*

#  rm /var/lib/tomcat9/BUILDING.txt
#  rm /var/lib/tomcat9/CONTRIBUTING.md
#  rm /var/lib/tomcat9/LICENSE
#  rm /var/lib/tomcat9/NOTICE
#  rm /var/lib/tomcat9/README.md
#  rm /var/lib/tomcat9/RELEASE-NOTES
#  rm /var/lib/tomcat9/RUNNING.txt
#  rm -r /var/lib/tomcat9/temp

  rm -f /usr/share/mysql/debian-start.inc.sh
  rm -f /usr/share/mysql/fill_help_tables.sql
  rm -f /usr/share/mysql/maria_add_gis_sp_bootstrap.sql
  rm -f /usr/share/mysql/mysql_performance_tables.sql
  rm -f /usr/share/mysql/mysql_sys_schema.sql
  rm -f /usr/share/mysql/mysql_system_tables.sql
  rm -f /usr/share/mysql/mysql_system_tables_data.sql
  rm -f /usr/share/mysql/mysql_test_data_timezone.sql
  rm -f /usr/share/mysql/mysql_test_db.sql
  rm -f /usr/share/mysql/wsrep.cnf
  rm -f /usr/share/mysql/wsrep_notify
  rm -f /usr/share/mysql/errmsg-utf8.txt

  rm -rf /etc/mysql/*
  rm -f /usr/bin/mysql_secure_installation
  rm -f /usr/bin/mariadb-secure-installation

  fnPrintText "remove install files SUCCESS"
  fnPrintLine
}

function fnFileAccessSetting() {
  fnPrintText "file access setting"
  fnLogLine

  chmod -R 700 /opt/connect/
  chmod -R 700 /etc/nginx/
  chmod -R 644 /etc/systemd/system/connect-controller-web.service
  chmod -R 644 /etc/systemd/system/connect-controller-api.service
  chmod -R 644 /etc/systemd/system/connect-controller-check.service
  chmod -R 644 /etc/systemd/system/connect-controller.service
  chmod -R 644 /etc/systemd/system/nginx.service
  chmod -R 644 /etc/systemd/system/mariadb.service
  systemctl daemon-reload
  fnPrintText "file access setting SUCCESS"
  fnPrintLine
}

function fnShellToBinary() {
  fnPrintText "thirdparty-conf-set.sh to BINARY"
  fnLogLine
  shc -f ${_PATH_PACKAGE}/sys/thirdparty-conf-set.sh
  mv ${_PATH_PACKAGE}/sys/thirdparty-conf-set.sh.x ${_PATH_PACKAGE}/sys/thirdparty-conf-set

  mkdir -p /opt/connect/controller/
  cp -f ${_PATH_PACKAGE}/sys/thirdparty-conf-set /opt/connect/controller/
  cp -f ${_PATH_PACKAGE}/sys/pribit_encoder /opt/connect/controller/

  fnPrintText "thirdparty-conf-set.sh to BINARY SUCCESS"
  fnPrintLine
}

function fnMariadbSystemdReset() {
  fnPrintText "mariadb systemd reset"
  fnLogLine

  systemctl stop mariadb.service
  systemctl disable mariadb.service >> $_INSTALL_LOG 2>&1
  #rm -f /etc/mysql/my.cnf
  rm -rf /etc/mysql/*
  rm -f /lib/systemd/system/mariadb.service
  systemctl daemon-reload

  sed -i '2d' ${_PATH_PACKAGE}/mysql/mariadb.service
  sed -i "2 i\Description=MariaDB ${_THIRDPARTY_MARIADB_MAJOR_VERSION} LTS database server" ${_PATH_PACKAGE}/mysql/mariadb.service

  chmod 644 ${_PATH_PACKAGE}/mysql/mariadb.service
  cp -f ${_PATH_PACKAGE}/mysql/mariadb.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable mariadb.service >> $_INSTALL_LOG 2>&1

  fnLogLine
  fnPrintText "mariadb systemd reset SUCCESS"
  fnPrintLine
}

function fnRemoveInstallScript() {
  rm -rf /usr/local/pribit
  exit 0
}

function fnOSCheck(){
  fnPrintText "This OS is ${_OS_DESCRIPTION}"
  fnPrintLine
  if [ "${_OS_RELEASE_VERSION}" != "${_OS_POSSIBLE_VERSION}" ]; then
    fnPrintLine
    echo
    echo "This OS is ${_OS_DESCRIPTION}"
    echo "Please change the OS version to Ubuntu ${_OS_POSSIBLE_VERSION} LTS"
    echo
    fnPrintLine
    echo
    read -n 1 -s -r -p "Press any Key to Exit...."
    echo
    exit
  fi
}

function fnDisableOSAutoUpdate(){
  fnPrintText "OS Auto Update Disable Setting"
  fnPrintLine
  if [ "$_OS_RELEASE_VERSION" = "24.04" ]; then
    fnPrintText "modify /etc/apt/apt.conf.d/20auto-upgrades"
    sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/g' /etc/apt/apt.conf.d/20auto-upgrades
    sed -i 's/APT::Periodic::Unattended-Upgrade "1";/APT::Periodic::Unattended-Upgrade "0";/g' /etc/apt/apt.conf.d/20auto-upgrades
    fnPrintText "disable unattended-upgrades"
    systemctl disable --now unattended-upgrades >> $_INSTALL_LOG 2>&1
  else
    fnPrintText "modify /etc/apt/apt.conf.d/10periodic"
    sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/g' /etc/apt/apt.conf.d/10periodic
    sed -i 's/APT::Periodic::Download-Upgradeable-Packages "1";/APT::Periodic::Download-Upgradeable-Packages "0";/g' /etc/apt/apt.conf.d/10periodic
    sed -i 's/APT::Periodic::AutocleanInterval "1";/APT::Periodic::AutocleanInterval "0";/g' /etc/apt/apt.conf.d/10periodic
    fnPrintText "modify /etc/apt/apt.conf.d/20auto-upgrades"
    sed -i 's/APT::Periodic::Update-Package-Lists "1";/APT::Periodic::Update-Package-Lists "0";/g' /etc/apt/apt.conf.d/20auto-upgrades
    sed -i 's/APT::Periodic::Unattended-Upgrade "1";/APT::Periodic::Unattended-Upgrade "0";/g' /etc/apt/apt.conf.d/20auto-upgrades
    fnPrintText "disable apt-daily.timer"
    systemctl disable apt-daily.timer >> $_INSTALL_LOG 2>&1
    fnPrintText "disable apt-daily-upgrade.timer"
    systemctl disable apt-daily-upgrade.timer >> $_INSTALL_LOG 2>&1
  fi
  fnPrintLine
  fnPrintText "OS Auto Update Disable Setting SUCCESS"
  fnPrintLine
}

function fnAptGetUpdate(){
  fnPrintText "apt-get update"
  fnLogLine
  fnPrintText "OFF-LINE mode do not need apt-get update"
  fnPrintLine
}

function fnAddRedisRepository(){
  fnPrintText "redis-server add apt repository set"
  fnLogLine
  if [ -e /usr/local/lib/libssl.so.1.1 ]; then
    chmod 744 /usr/local/lib/libssl.so.1.1
  fi
  sleep 1
  fnLogLine
  fnPrintText "OFF-LINE mode do not need add redis-server apt repository set"
  fnPrintLine
}

function fnRedisJsonPluginSetting() {
  fnPrintText "redis-server add json plugin"
  fnLogLine
  _REDIS_PLUGIN="/etc/redis/plugin/librejson.so"
  if [ -e "${_REDIS_PLUGIN}" ]; then
    fnPrintText "redis-server already add json plugin(librejson.so)"
    fnPrintLine
  else
    {
      mkdir -p /etc/redis/plugin/
      cp ${_PATH_PACKAGE}/thirdparty-packages/redis-server/plugin/librejson.so /etc/redis/plugin/
      chmod 755 /etc/redis/plugin/librejson.so
      sleep 1
      _REDIS_EXISTS_CONF="/etc/redis/redis.conf"
      if [ -e "${_REDIS_EXISTS_CONF}" ]; then
        sed -i'' -r -e "/# loadmodule \/path\/to\/other_module.so/a\loadmodule \/etc\/redis\/plugin\/librejson.so" /etc/redis/redis.conf
        sed -i "s/appendonly yes/appendonly no/g" /etc/redis/redis.conf
        sleep 1
        systemctl enable redis-server.service >> $_INSTALL_LOG 2>&1
        systemctl daemon-reload
        systemctl restart redis-server.service
        sleep 1
      fi
    } &
    _REDIS_PLUGIN_PID=$!
    fnShowProgress $_REDIS_PLUGIN_PID "redis-server add json plugin(librejson.so)"
    wait $_REDIS_PLUGIN_PID
    fnPrintText "redis-server add json plugin(librejson.so) SUCCESS"
    fnPrintLine
  fi
}

function fnMakeRedisServiceFile() {
  rm -f /etc/systemd/system/redis-server.service
  /usr/bin/cat << EOF > /etc/systemd/system/redis-server.service
[Unit]
Description=Advanced key-value store
After=network.target
Documentation=http://redis.io/documentation, man:redis-server(1)

[Service]
Type=notify
ExecStartPre=/opt/thirdparty/redis/redis-conf-set --redis_decode
ExecStart=/usr/bin/redis-server /etc/redis/redis.conf
ExecStop=/bin/kill -s QUIT \$MAINPID
ExecStartPost=/opt/thirdparty/redis/redis-conf-set --redis_post
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
ReadWriteDirectories=-/opt/thirdparty/redis

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
  _HMAC_USER_PW=$(echo -n "$PRIBIT_USER_PW" | openssl dgst -sha256 -hmac "pribittechnology" | awk '{print $2}')

  rm -f /opt/thirdparty/redis/redis.conf
  mkdir -p /opt/thirdparty/redis/

  /usr/bin/cat << EOF > /opt/thirdparty/redis/redis.conf
loadmodule /etc/redis/plugin/librejson.so
bind 127.0.0.1
protected-mode yes
port 6379
masterauth $_HMAC_USER_PW
requirepass $_HMAC_USER_PW
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
EOF
  chmod 640 /opt/thirdparty/redis/redis.conf
}

function fnEncodeRedisConf() {
  rm -f /opt/thirdparty/redis/redis.conf.enc
  cp /opt/connect/controller/pribit_encoder /opt/thirdparty/redis/pribit_redis_encoder
  /opt/thirdparty/redis/pribit_redis_encoder /opt/thirdparty/redis/redis.conf
  rm -f /opt/thirdparty/redis/redis.conf
  chown -R redis:redis /opt/thirdparty/redis/
}

function fnMakeRedisConfSetFile() {
  rm -f /opt/thirdparty/redis/redis-conf-set.sh

  /usr/bin/cat << EOF > /opt/thirdparty/redis/redis-conf-set.sh
#!/bin/bash

function fnRedisConfFileDecode() {
  /opt/thirdparty/redis/pribit_redis_encoder /opt/thirdparty/redis/redis.conf.enc
  mv /opt/thirdparty/redis/redis.conf /etc/redis/redis.conf
  chmod 640 /etc/redis/redis.conf
  chown redis:redis /etc/redis/redis.conf
  return 0
}

function fnRedisConfFileRemove() {
  /usr/bin/rm -f /etc/redis/redis.conf
  return 0
}

function fnHelp() {
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
  fnHelp
else
  for i in "\$@"
  do
  case \$i in
    --redis_decode)
        fnRedisConfFileDecode;;
    --redis_post)
        fnRedisConfFileRemove;;
    --help)
        fnHelp;;
    *)
        fnHelp;;
  esac
  done
fi
EOF

}

function fnRedisConfSetFileBinary() {
  rm -f /opt/thirdparty/redis/redis-conf-set
  shc -f /opt/thirdparty/redis/redis-conf-set.sh
  rm -f /opt/thirdparty/redis/redis-conf-set.sh /opt/thirdparty/redis/redis-conf-set.sh.x.c
  mv /opt/thirdparty/redis/redis-conf-set.sh.x /opt/thirdparty/redis/redis-conf-set
  chmod 700 /opt/thirdparty/redis/redis-conf-set
  chown redis:redis /opt/thirdparty/redis/redis-conf-set
}

function fnRedisSetting() {
  fnPrintText "redis set"
  fnLogLine
  {
    # STEP  1 : STOP REDIS SERVICE
    systemctl stop redis-server.service
    # STEP  2 : DISABLE REDIS SERVICE
    systemctl disable redis-server.service >> $_INSTALL_LOG 2>&1
    # STEP  3 : DELETE FILE redis-server.service
    find / -type f -name redis-server.service 2>/dev/null | xargs rm -f
    rm -f /etc/redis/plugin/rejson.so
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
    systemctl enable redis-server.service >> $_INSTALL_LOG 2>&1
    # STEP 11 : START REDIS SERVICE
    systemctl restart redis-server.service
  } &
  _REDIS_SETTING_PID=$!
  fnShowProgress $_REDIS_SETTING_PID "redis setting"
  wait $_REDIS_SETTING_PID
  fnLogLine
  fnPrintText "redis set SUCCESS"
  fnPrintLine
}

function fnThirdpartyVersionCheck(){
  echo "OS Version              : $(lsb_release -d | awk '{print $2,$3,$4 }')" | tee -a $_INSTALL_LOG
  echo "OS Kernel Version       : $(uname -a | awk '{print $3}')" | tee -a $_INSTALL_LOG
  echo "Openssl Version         : v$(openssl version | awk '{print $2}')" | tee -a $_INSTALL_LOG
  echo "Nginx Version           : v$(nginx -v 2>&1 | awk -F/ '{print $2}')" | tee -a $_INSTALL_LOG
  echo "OpenJDK Version         : v$(dpkg -l | grep "jre" | awk 'NR==1{split($3,n,"+"); print n[1]}')" | tee -a $_INSTALL_LOG
  echo "Embedded Tomcat Version : v$(find /tmp -name tomcat-embed-core-*.jar 2>&1 | awk '{split($1,n,"tomcat-embed-core-"); split(n[2],v,".jar"); print v[1] }')" | tee -a $_INSTALL_LOG
  echo "MariaDB Version         : v$(mariadb --version | awk '{split($5,v,"-"); print v[1] }')" | tee -a $_INSTALL_LOG
  echo "Redis Version           : v$(redis-cli --version | awk '{ print $2 }')" | tee -a $_INSTALL_LOG
  echo "Keepalived Version      : $(keepalived --version 2>&1 | awk 'NR==1{print $2}')" | tee -a $_INSTALL_LOG
  echo "Snmpd Version           : v$(snmpd -version | awk 'NR==2{print $3}')" | tee -a $_INSTALL_LOG
  echo "bwm-ng Version          : $(bwm-ng --version 2>&1 | awk 'NR==1{print $5}')" | tee -a $_INSTALL_LOG
  fnPrintLine
}

function fnControllerInstall(){
  mkdir -p "$(dirname "$_INSTALL_LOG")" && touch "$_INSTALL_LOG"
  rm -f "$_INSTALL_LOG"
  fnPrintLine
  fnPrintText "Installing ${_PRODUCT_NAME}"
  echo "$(date +'%Y-%m-%d %H:%M:%S') | The installation process is saved in a log file"
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') | log file path \033[32;1m"\'${_INSTALL_LOG}\'"\033[0m"
  fnOSCheck
  fnDefaultDbSchema
  fnDisableOSAutoUpdate
  fnDbmsInputSetPassword
  fnDBRiskInputUserSetting
  fnConnectControllerRestrictedIP

  fnAptGetUpdate
  fnInstallPkg "net-tools"
  fnInstallPkg "rdate"
  fnTimeSetting
  if [ "$_OS_RELEASE_VERSION" = "24.04" ]; then
    fnInstallPkg "vim-nox"
    fnInstallPkg "rsyslog"
  fi
  fnRsyslogSetting
  fnCheckService
  fnInstallPkg "openjdk-17-jre"
  fnInstallPkg "build-essential"
  fnInstallPkg "libpcre3-dev"
  fnInstallPkg "zlib1g-dev"
  fnInstallPkg "libssl-dev"
  fnInstallPkg "libgd-dev"
  fnInstallPkg "libxml2-dev"

  local _MARIADB_PKG="mariadb-server"
  local _MARIADB_RET=$(dpkg -l | grep ${_MARIADB_PKG} | awk '{print $2}')
  if [ -z "${_MARIADB_RET}" ]; then
    fnInstallPkg "apt-transport-https"
    fnInstallPkg "expect"
    fnAddMariadbRepository
    fnInstallPkg "mariadb-server"
    fnInstallPkg "mariadb-backup"
    sleep 1
    if [ -e "${_BACKUP_SQL}" ]; then
      fnPrintText "check required mariadb database"
      fnLogLine
      mariadb-upgrade -uroot -p$DB_ROOT_PW >> $_INSTALL_LOG 2>&1 &
      fnShowProgress $! "check and upgrade mariadb database"
      wait $!
      fnPrintText "check and upgrade mariadb database finished"
      fnPrintLine
      fnDbRiskUpgradeSetting
    else
      fnMariadbConfiguraionExpect
      sleep 1
      fnDbRiskSetting
      sleep 1
    fi
  else
    fnPrintText "${_MARIADB_PKG} installing..."
    fnLogLine
    fnPrintText "${_MARIADB_PKG} already installed."
    fnPrintLine
    fnDbRiskUpgradeSetting
  fi

  fnInstallPkg "shc"
  fnShellToBinary
  fnMariadbSystemdReset
  fnHostnameSetting
  fnAddControllerService
  fnOpensslCompileBuild
  fnNginxCompileBuild
  fnAddRedisRepository
  fnInstallPkg "redis-server"
  fnRedisJsonPluginSetting
  fnRedisSetting
  fnInstallPkg "keepalived"
  fnInstallPkg "snmpd"
  fnInstallPkg "snmp"
  fnInstallPkg "bwm-ng"
#	fnRemoveCompileLibraries
  sleep 1
  fnFileAccessSetting
  sleep 1
  fnPrintText "make properties files"
  fnLogLine
  {
    java -jar /opt/connect/controller/util/controller-util-1.0.jar setup $PRIBIT_USER $PRIBIT_USER_PW $ALLOWED_IP $_ZTNA_DB_SCHEMA >> $_INSTALL_LOG 2>&1
  } &
  _CREATE_PROPERTIES_PID=$!
  fnShowProgress $_CREATE_PROPERTIES_PID "making properties files"
  wait $_CREATE_PROPERTIES_PID
  fnPrintText "make properties files SUCCESS"
  fnPrintLine
  fnRemoveInstallFiles
  fnLogText "Start ${_PRODUCT_NAME}"
  {
    sleep 1
    systemctl start mariadb.service
    sleep 5
    java -jar /opt/connect/controller/util/controller-util-1.0.jar legacy >> $_INSTALL_LOG 2>&1
    sleep 1
    systemctl start ${_SERVICE_CTRL_WEB}.service
    sleep 1
    systemctl start ${_SERVICE_CTRL_API}.service
    sleep 1
    systemctl start nginx.service
    sleep 1
    systemctl start ${_SERVICE_CTRL}.service
    sleep 1
    systemctl start ${_SERVICE_CTRL_CHECK}.service
    sleep 1
    sleep 45
  } &
  _START_SERVICE_PID=$!
  fnShowProgress $_START_SERVICE_PID "Start ${_PRODUCT_NAME}"
  wait $_START_SERVICE_PID
  fnLogLine
  fnPrintText "The installation was completed normally."
  fnPrintLine
  fnThirdpartyVersionCheck
  echo "$(date +'%Y-%m-%d %H:%M:%S') | You can check the installation process through the log file"
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') | log file path \033[32;1m"\'${_INSTALL_LOG}\'"\033[0m"
  echo "========================================================================================="
  fnRemoveInstallScript&
}
fnControllerInstall