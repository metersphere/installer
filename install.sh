#!/bin/bash
CURRENT_DIR=$(
   cd "$(dirname "$0")"
   pwd
)
os=`uname -a`
function log() {
   message="[MeterSphere Log]: $1 "
   echo -e "${message}" 2>&1 | tee -a ${CURRENT_DIR}/install.log
}
args=$@

compose_files="-f docker-compose-base.yml"
set -a
if [[ $os =~ 'Darwin' ]];then
    sed -i -e "s#MS_BASE=.*#MS_BASE=~#g" ${CURRENT_DIR}/install.conf
    sed -i -e "s#MS_KAFKA_HOST=.*#MS_KAFKA_HOST=$(ipconfig getifaddr en0)#g" ${CURRENT_DIR}/install.conf
fi
source ${CURRENT_DIR}/install.conf
MS_JMETER_TAG=$(cat install.conf | grep MS_JMETER_TAG | awk -F= 'NR==1{print $2}')
if [[ -f ${MS_BASE}/metersphere/.env ]];then
   echo MS_TAG=$MS_TAG >> ${MS_BASE}/metersphere/.env
   echo MS_JMETER_TAG=$MS_JMETER_TAG >> ${MS_BASE}/metersphere/.env
   source ${MS_BASE}/metersphere/.env
fi
set +a

mkdir -p ${MS_BASE}/metersphere
cp -r ./metersphere ${MS_BASE}/

sed -i -e "s#MS_BASE=.*#MS_BASE=${MS_BASE}#g" msctl
cp msctl /usr/local/bin && chmod +x /usr/local/bin/msctl
ln -s /usr/local/bin/msctl /usr/bin/msctl 2>/dev/null

echo -e "======================= 开始安装 =======================" 2>&1 | tee -a ${CURRENT_DIR}/install.log

echo "time: $(date)"

#Install docker & docker-compose
##Install Latest Stable Docker Release
if which docker >/dev/null; then
   log "检测到 Docker 已安装，跳过安装步骤"
   log "启动 Docker "
   service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
else
   if [[ -d docker ]]; then
      log "... 离线安装 docker"
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log

   else
      log "... 在线安装 docker"
      curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 | tee -a ${CURRENT_DIR}/install.log
      sudo sh get-docker.sh --mirror Aliyun 2>&1 | tee -a ${CURRENT_DIR}/install.log
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${CURRENT_DIR}/install.log
   fi

fi

docker ps 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "Docker 未正常启动，请先安装并启动 Docker 服务后再次执行本脚本"
   exit
fi

##Install Latest Stable Docker Compose Release
if which docker-compose >/dev/null; then
   log "检测到 Docker Compose 已安装，跳过安装步骤"
else
   if [[ -d docker ]]; then
      log "... 离线安装 docker-compose"
      cp docker/bin/docker-compose /usr/bin/
      chmod +x /usr/bin/docker-compose
   else
      log "... 在线安装 docker-compose"
      COMPOSEVERSION=$(curl -s https://github.com/docker/compose/releases/latest/download 2>&1 | grep -Po [0-9]+\.[0-9]+\.[0-9]+)
      curl -L "https://github.com/docker/compose/releases/download/$COMPOSEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 | tee -a ${CURRENT_DIR}/install.log
      chmod +x /usr/local/bin/docker-compose
      ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
   fi
fi

docker-compose version 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "docker-compose 未正常安装，请先安装 docker-compose 后再次执行本脚本"
   exit
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
   log "... 不支持的安装模式，请从 [ allinone | server | node-controller ] 中进行选择"
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

cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) config 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "docker-compose 版本与配置文件不兼容，请重新安装最新版本的 docker-compose"
   exit
fi

export COMPOSE_HTTP_TIMEOUT=180
cd ${CURRENT_DIR}
# 加载镜像
if [[ -d images ]]; then
   log "加载镜像"
   for i in $(ls images); do
      docker load -i images/$i 2>&1 | tee -a ${CURRENT_DIR}/install.log
   done
else
   log "拉取镜像"
   cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) pull 2>&1 | tee -a ${CURRENT_DIR}/install.log
   docker pull ${MS_PREFIX}/jmeter-master:${MS_JMETER_TAG} 2>&1 | tee -a ${CURRENT_DIR}/install.log
   cd -
fi

log "启动服务"
cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) down -v 2>&1 | tee -a ${CURRENT_DIR}/install.log
cd ${MS_BASE}/metersphere && docker-compose $(cat compose_files) up -d 2>&1 | tee -a ${CURRENT_DIR}/install.log

msctl status 2>&1 | tee -a ${CURRENT_DIR}/install.log

echo -e "======================= 安装完成 =======================\n" 2>&1 | tee -a ${CURRENT_DIR}/install.log
cat << "EOF"
                                  _
                               .-(_)
                              / _/
                           .-'   \
                          /       '.
                        ,-~--~-~-~-~-,
                       {__.._...__..._}             ,888,
       ,888,          /\##"  6  6  "##/\          ,88' `88,
     ,88' '88,__     |(\`    (__)    `/)|     __,88'     `88
    ,88'   .8(_ \_____\_    '----'    _/_____/ _)8.       8'
    88    (___)\ \      '-.__    __.-'      / /(___)
    88    (___)88 |          '--'          | 88(___)
    8'      (__)88,___/                \___,88(__)
              __`88,_/__________________\_,88`__
             /    `88,       |88|       ,88'    \
            /        `88,    |88|    ,88'        \
           /____________`88,_\88/_,88`____________\
          /88888888888888888;8888;88888888888888888\
         /^^^^^^^^^^^^^^^^^^`/88\\^^^^^^^^^^^^^^^^^^\
        /                    |88| \============,     \
       /_  __  __  __   _ __ |88|_|^  MERRY    | _ ___\
       |;:.                  |88| | CHRISTMAS! |      |
       |;;:.                 |88| '============'      |
       |;;:.                 |88|                     |
       |::.                  |88|                     |
       |;;:'                 |88|                     |
       |:;,                  |88|                     |
       '---------------------""""---------------------'
EOF
echo -e "请通过以下方式访问:\n URL: http://\$LOCAL_IP:${MS_PORT}\n 用户名: admin\n 初始密码: metersphere" 2>&1 | tee -a ${CURRENT_DIR}/install.log
echo -e "您可以使用命令 'msctl status' 检查服务运行情况.\n" 2>&1 | tee -a ${CURRENT_DIR}/install.log-a ${CURRENT_DIR}/install.log
