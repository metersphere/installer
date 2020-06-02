#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
args=$@

compose_files="-f docker-compose-base.yml"
set -a
source ${CURRENT_DIR}/install.conf
set +a

cp -r ./metersphere ${MS_BASE}
sed -i -e "s\MS_BASE=.*\MS_BASE=${MS_BASE}\g" msctl
cp msctl /usr/local/bin && chmod +x /usr/local/bin/msctl
ln -s /usr/local/bin/msctl /usr/bin/msctl

cd ${MS_BASE}/metersphere
env | grep MS_ > .env

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
esac
if [ ${MS_MODE} != "node-controller" ];then
   # 是否使用外部数据库
   if [ ${MS_EXTERNAL_MYSQL} = "false" ];then
      mkdir -p ${MS_BASE}/metersphere/data/mysql
      compose_files="${compose_files} -f docker-compose-mysql.yml"
      sed -i -e "s#\${MS_MYSQL_DB}#${MS_MYSQL_DB}#g" ${MS_BASE}/metersphere/bin/mysql/init.sql
   else
      sed -i -e "/#external_mysql=false/{N;N;d;}" ${MS_BASE}/metersphere/docker-compose*
   fi
   # 是否使用外部 Kafka
   if [ ${MS_EXTERNAL_KAFKA} = "false" ];then
      mkdir -p ${MS_BASE}/metersphere/data/kafka
      mkdir -p ${MS_BASE}/metersphere/data/zookeeper
      compose_files="${compose_files} -f docker-compose-kafka.yml" 
   else
      sed -i -e "/#external_kafka=false/{N;N;d;}" ${MS_BASE}/metersphere/docker-compose*
   fi
fi
echo ${compose_files} > ${MS_BASE}/metersphere/compose_files 

cd ${CURRENT_DIR}
# 加载镜像
if [[ -d images ]];then
   echo "... 加载镜像"
    for i in $(ls images);do
        docker load -i images/$i
    done
else
    cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) pull
    cd -
fi

cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) up -d