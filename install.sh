#!/bin/bash

__current_dir=$(
   cd "$(dirname "$0")"
   pwd
)
args=$@
__os=`uname -a`

function log() {
   message="[MeterSphere Log]: $1 "
   echo -e "${message}" 2>&1 | tee -a ${__current_dir}/install.log
}
set -a
__local_ip=$(hostname -I|cut -d" " -f 1)
source ${__current_dir}/install.conf

export INSTALL_TYPE='install'
if [ -f ~/.msrc ];then
  source ~/.msrc > /dev/null
  echo "存在已安装的 MeterSphere, 安装目录为 ${MS_BASE}/metersphere, 执行升级流程"
  INSTALL_TYPE='upgrade'
elif [ -f /usr/local/bin/msctl ];then
  MS_BASE=$(cat /usr/local/bin/msctl | grep MS_BASE= | awk -F= '{print $2}' 2>/dev/null)
  echo "存在已安装的 MeterSphere, 安装目录为 ${MS_BASE}/metersphere, 执行升级流程"
  INSTALL_TYPE='upgrade'
else
  MS_BASE=$(cat ${__current_dir}/install.conf | grep MS_BASE= | awk -F= '{print $2}' 2>/dev/null)
  echo "安装目录为 ${MS_BASE}/metersphere, 开始进行安装"
  INSTALL_TYPE='install'
fi
if [ ${MS_EXTERNAL_KAFKA} = 'false' ];then
   if [[ ${__os} =~ 'Darwin' ]];then
      MS_BASE=${MS_BASE:-~}
      __local_ip=$(ipconfig getifaddr en0)
      sed -i -e "s#MS_KAFKA_HOST=.*#MS_KAFKA_HOST=${__local_ip}#g" ${__current_dir}/install.conf
   fi
   sed -i -e "s#MS_KAFKA_HOST=.*#MS_KAFKA_HOST=${__local_ip}#g" ${__current_dir}/install.conf
fi
set +a

__current_version=$(cat ${MS_BASE}/metersphere/version 2>/dev/null || echo "")
if [[ ${__current_version} =~ "lts" ]];then
   if [[ ! $(cat ${__current_dir}/metersphere/version) =~ "lts" ]];then
      log "从LTS版本升级到非LTS版本，此版本包含实验性功能请做好数据备份工作"
      log "从2.0开始，我们去掉了zookeeper，升级了kafka和mysql，升级前请执行 msctl stop && docker rm zookeeper && docker rm kafka; 如果已经升级至2.0请忽略这条信息"
      read -p "是否确认升级? [n/y]" __choice </dev/tty
      case "$__choice" in
         y|Y) echo "继续安装...";;
         n|N) echo "退出安装..."&exit;;
         *) echo "退出安装..."&exit;;
      esac
   fi
else
   if [[ $(cat ${__current_dir}/metersphere/version) =~ "lts" && ${INSTALL_TYPE} == "upgrade" ]];then
      log "\e[31m从非LTS版本升级到LTS版本后，后续只能自动升级LTS版本，如升级非LTS版本，需手动升级！\e[0m"
      read -p "是否确认升级? [n/y]" __choice </dev/tty
      case "$__choice" in
         y|Y) echo "继续安装...";;
         n|N) echo "退出安装..."&exit;;
         *) echo "退出安装..."&exit;;
       esac
   fi
fi

log "拷贝安装文件到目标目录"

mkdir -p ${MS_BASE}/metersphere
cp -f ./metersphere/version ${MS_BASE}/metersphere/version
cp -rv --suffix=.$(date +%Y%m%d-%H%M) ./metersphere ${MS_BASE}/

# 记录MeterSphere安装路径
echo "MS_BASE=${MS_BASE}" > ~/.msrc
# 安装 msctl 命令
cp msctl /usr/local/bin && chmod +x /usr/local/bin/msctl
ln -s /usr/local/bin/msctl /usr/bin/msctl 2>/dev/null

log "======================= 开始安装 ======================="
#Install docker & docker-compose
##Install Latest Stable Docker Release
if which docker >/dev/null; then
   log "检测到 Docker 已安装，跳过安装步骤"
   log "启动 Docker "
   service docker start 2>&1 | tee -a ${__current_dir}/install.log
else
   if [[ -d docker ]]; then
      log "... 离线安装 docker"
      chmod +x docker/bin/*
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod 754 /etc/systemd/system/docker.service
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${__current_dir}/install.log

   else
      log "... 在线安装 docker"
      curl -fsSL https://resource.fit2cloud.com/get-docker-linux.sh -o get-docker.sh 2>&1 | tee -a ${__current_dir}/install.log
      sudo sh get-docker.sh 2>&1 | tee -a ${__current_dir}/install.log
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${__current_dir}/install.log
   fi

fi

# 检查docker服务是否正常运行
docker ps 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "Docker 未正常启动，请先安装并启动 Docker 服务后再次执行本脚本"
   exit
fi

# 配置docker服务开机自启
if which systemctl >/dev/null; then
  systemctl enable docker
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
      curl -L https://resource.fit2cloud.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s | tr A-Z a-z)-`uname -m` -o /usr/local/bin/docker-compose 2>&1 | tee -a ${__current_dir}/install.log
      chmod +x /usr/local/bin/docker-compose
      ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
   fi
fi
# 检查docker-compose是否正常
docker-compose version 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "docker-compose 未正常安装，请先安装 docker-compose 后再次执行本脚本"
   exit
fi

# 将配置信息存储到安装目录的环境变量配置文件中
echo '' >> ${MS_BASE}/metersphere/.env
cp -f ${__current_dir}/install.conf ${MS_BASE}/metersphere/install.conf.example
# 通过加载环境变量的方式保留已修改的配置项，仅添加新增的配置项
source ${__current_dir}/install.conf
source ~/.msrc >/dev/null 2>&1
__ms_image_tag=${MS_IMAGE_TAG}
__ms_jmeter_image=${MS_JMETER_IMAGE}
source ${MS_BASE}/metersphere/.env
# 把原来kafka的配置合并成IP
if [ ${MS_KAFKA_HOST} = 'kafka' ];then
  MS_KAFKA_HOST=${__local_ip}
fi
export MS_IMAGE_TAG=${__ms_image_tag}
export MS_JMETER_IMAGE=${__ms_jmeter_image}
env | grep MS_ > ${MS_BASE}/metersphere/.env
ln -s ${MS_BASE}/metersphere/.env ${MS_BASE}/metersphere/install.conf 2>/dev/null
grep "127.0.0.1 $(hostname)" /etc/hosts >/dev/null || echo "127.0.0.1 $(hostname)" >> /etc/hosts
msctl generate_compose_files
msctl config 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   msctl config
   log "docker-compose 版本与配置文件不兼容或配置文件存在问题，请重新安装最新版本的 docker-compose 或检查配置文件"
   exit
fi

exec > >(tee -a ${__current_dir}/install.log) 2>&1
set -e
export COMPOSE_HTTP_TIMEOUT=180
cd ${__current_dir}
# 加载镜像
if [[ -d images ]]; then
   log "加载镜像"
   for i in $(ls images); do
      docker load -i images/$i
   done
else
   log "拉取镜像"
   msctl pull
   docker pull ${MS_JMETER_IMAGE}
   curl -sfL https://resource.fit2cloud.com/installation-log.sh | sh -s ms ${INSTALL_TYPE} ${MS_IMAGE_TAG}
   cd -
fi

log "启动服务"
msctl down -v
msctl up -d --remove-orphans

msctl status

echo -e "======================= 安装完成 =======================\n"

echo -e "请通过以下方式访问:\n URL: http://\$LOCAL_IP:${MS_SERVER_PORT}\n 用户名: admin\n 初始密码: metersphere"
echo -e "企业用户升级后需手动设置 install.conf 中的 MS_UI_ENABLED=true 并执行 'msctl reload' 来开启UI功能"
echo -e "您可以使用命令 'msctl status' 检查服务运行情况.\n"
