#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")";pwd)
source ${CURRENT_DIR}/install_config.sh
args=$@

compose_files="-f docker-compose-base.yml"

echo "== 开始安装 MeterSphere =="
INSTALL_BASE=$(install_config base_dir)
echo "... 拷贝资源至安装路径"
cp -r ./metersphere ${INSTALL_BASE} && echo "... 拷贝资源至安装路径成功"
echo "... 替换安装配置参数"
for i in ${support_config};do
   key=${i}
   value=$(install_config $i)
   if [[ -n $key && -n $value ]];then
      sed -i -e "s#\${${key}}#${value}#g" ${INSTALL_BASE}/metersphere/conf/* ${INSTALL_BASE}/metersphere/bin/mysql/* ${INSTALL_BASE}/metersphere/docker-compose*
   fi
done
sed -i -e "s\BASE_DIR=.*\BASE_DIR=${INSTALL_BASE}\g" msctl
cp msctl /usr/local/bin && chmod +x /usr/local/bin/msctl
echo "... 配置安装模式"
INSTALL_MODE=$(install_config install_mode)
case ${INSTALL_MODE} in
   allinone)
      mkdir -p ${INSTALL_BASE}/metersphere/data/jmeter
      compose_files="${compose_files} -f docker-compose-server.yml -f docker-compose-node-controller.yml"
      ;;
   server)
      compose_files="${compose_files} -f docker-compose-server.yml" 
      ;;
   node-controller)
      mkdir -p ${INSTALL_BASE}/metersphere/data/jmeter
      compose_files="${compose_files} -f docker-compose-node-controller.yml" 
      ;;
   *)
      echo "... 不支持的安装模式，请从 [ allinone | server | node-controller ] 中进行选择"
esac
# 是否使用外部数据库
if [ $(install_config external_mysql) = "false" ];then
   mkdir -p ${INSTALL_BASE}/metersphere/data/mysql
   compose_files="${compose_files} -f docker-compose-mysql.yml"
else
   sed -i -e "/#external_mysql=false/{N;N;d;}" ${INSTALL_BASE}/metersphere/docker-compose*
fi
# 是否使用外部 Kafka
if [ $(install_config external_kafka) = "false" ];then
   mkdir -p ${INSTALL_BASE}/metersphere/data/kafka
   mkdir -p ${INSTALL_BASE}/metersphere/data/zookeeper
   compose_files="${compose_files} -f docker-compose-kafka.yml" 
else
   sed -i -e "/#external_kafka=false/{N;N;d;}" ${INSTALL_BASE}/metersphere/docker-compose*
fi
echo ${compose_files} > ${INSTALL_BASE}/metersphere/compose_files 
echo "... 启动 MeterSphere"
# 加载镜像
if [[ -d images ]];then
    for i in $(ls images);do
        docker load -i images/$i
    done
else
    cd ${INSTALL_BASE}/metersphere && docker-compose $(cat compose_files) pull
    cd -
fi

cd ${INSTALL_BASE}/metersphere && docker-compose $(cat compose_files) up -d