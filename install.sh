#!/bin/bash

CURRENT_DIR=$(
   cd "$(dirname "$0")"
   pwd
)
args=$@

compose_files="-f docker-compose-base.yml"
set -a
source ${CURRENT_DIR}/install.conf
set +a

cp -r ./metersphere ${MS_BASE}
sed -i -e "s\MS_BASE=.*\MS_BASE=${MS_BASE}\g" msctl
cp msctl /usr/local/bin && chmod +x /usr/local/bin/msctl
ln -s /usr/local/bin/msctl /usr/bin/msctl

#Install docker & docker-compose
##Install Latest Stable Docker Release
if which docker; then
   echo "Docker already installed, skip installation"
   service docker start
else
   if [[ -d docker ]]; then
      echo "... 离线安装 docker"
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      service docker start

   else
      echo "... 在线安装 docker"
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      service docker start
      echo "Docker Installation done"
   fi

fi

##Install Latest Stable Docker Compose Release
if which docker-compose; then
   echo "Docker Compose already installed, skip installation"
else
   if [[ -d docker ]]; then
      echo "... 离线安装 docker-compose"
      cp docker/bin/docker-compose /usr/bin/
      chmod +x /usr/bin/docker-compose
   else
      echo "... 在线安装 docker-compose"
      COMPOSEVERSION=$(curl -s https://github.com/docker/compose/releases/latest/download 2>&1 | grep -Po [0-9]+\.[0-9]+\.[0-9]+)
      curl -L "https://github.com/docker/compose/releases/download/$COMPOSEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
      echo "Docker Compose Installation done"
   fi
fi

cd ${MS_BASE}/metersphere
env | grep MS_ >.env

case ${MS_MODE} in
allinone)
   mkdir -p ${MS_BASE}/metersphere/data/jmeter
   compose_files="${compose_files} -f docker-compose-server.yml -f docker-compose-node-controller.yml"
   ;;
server)
   compose_files="${compose_files} -f docker-compose-server.yml"
   ;;
node-controller)
   mkdir -p ${MS_BASE}/metersphere/data/jmeter
   compose_files="${compose_files} -f docker-compose-node-controller.yml"
   ;;
*)
   echo "... 不支持的安装模式，请从 [ allinone | server | node-controller ] 中进行选择"
   ;;
esac
if [ ${MS_MODE} != "node-controller" ]; then
   # 是否使用外部数据库
   if [ ${MS_EXTERNAL_MYSQL} = "false" ]; then
      mkdir -p ${MS_BASE}/metersphere/data/mysql
      compose_files="${compose_files} -f docker-compose-mysql.yml"
      sed -i -e "s#\${MS_MYSQL_DB}#${MS_MYSQL_DB}#g" ${MS_BASE}/metersphere/bin/mysql/init.sql
   else
      sed -i -e "/#MS_EXTERNAL_MYSQL=false/{N;N;N;d;}" ${MS_BASE}/metersphere/docker-compose*
   fi
   # 是否使用外部 Kafka
   if [ ${MS_EXTERNAL_KAFKA} = "false" ]; then
      mkdir -p ${MS_BASE}/metersphere/data/kafka
      mkdir -p ${MS_BASE}/metersphere/data/zookeeper
      compose_files="${compose_files} -f docker-compose-kafka.yml"
   else
      sed -i -e "/#MS_EXTERNAL_KAFKA=false/{N;N;N;d;}" ${MS_BASE}/metersphere/docker-compose*
   fi
fi
echo ${compose_files} >${MS_BASE}/metersphere/compose_files

cd ${CURRENT_DIR}
# 加载镜像
if [[ -d images ]]; then
   echo "... 加载镜像"
   for i in $(ls images); do
      docker load -i images/$i
   done
else
   cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) pull
   cd -
fi

cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) up -d
