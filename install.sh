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
if [[ ${__os} =~ 'Darwin' ]];then
    sed -i -e "s#MS_BASE=.*#MS_BASE=~#g" ${__current_dir}/install.conf
    __local_ip=$(ipconfig getifaddr en0)
   sed -i -e "s#MS_KAFKA_HOST=.*#MS_KAFKA_HOST=${__local_ip}#g" ${__current_dir}/install.conf
fi
sed -i -e "s#MS_KAFKA_EXT_HOST=.*#MS_KAFKA_EXT_HOST=${__local_ip}#g" ${__current_dir}/install.conf
source ${__current_dir}/install.conf
set +a

__current_version=$(cat ${MS_BASE}/metersphere/version 2>/dev/null || echo "")
if [[ ${__current_version} =~ "lts" ]];then
   if [[ ! $(cat ${__current_dir}/metersphere/version) =~ "lts" ]];then
      log "不支持从LTS版本升级到非LTS版本"
      exit 1
   fi
else
   if [[ $(cat ${__current_dir}/metersphere/version) =~ "lts" ]];then
      log "\e[31m从非LTS版本升级到LTS版本后，后续将只能升级新的LTS版本，无法再自动升级到非LTS版本\e[0m"
      read -p "是否确认升级? [n/y]" __choice
      case "$__choice" in
         y|Y) echo "继续安装...";;
         n|N) echo "退出安装..."&exit;;
         *) echo "退出安装..."&exit;;
       esac
   fi
fi

log "${MS_BASE}/metersphere 目录已存在，进行升级流程"

mkdir -p ${MS_BASE}/metersphere
cp -ruv --suffix=.$(date +%Y%m%d-%H%M) ./metersphere ${MS_BASE}/

# 记录MeterSphere安装路径
echo "MS_BASE=${MS_BASE}" > ~/.msrc\
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
      cp docker/bin/* /usr/bin/
      cp docker/service/docker.service /etc/systemd/system/
      chmod +x /usr/bin/docker*
      chmod 754 /etc/systemd/system/docker.service
      log "... 启动 docker"
      service docker start 2>&1 | tee -a ${__current_dir}/install.log

   else
      log "... 在线安装 docker"
      curl -fsSL https://get.docker.com -o get-docker.sh 2>&1 | tee -a ${__current_dir}/install.log
      sudo sh get-docker.sh --mirror Aliyun 2>&1 | tee -a ${__current_dir}/install.log
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
      curl -L https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose 2>&1 | tee -a ${__current_dir}/install.log
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
eval "cat <<EOF
# ADDED ON $(date)
$(<install.conf)
# END
EOF" | cat - ${MS_BASE}/metersphere/.env > temp && mv temp ${MS_BASE}/metersphere/.env
diff ${__current_dir}/install.conf ${MS_BASE}/metersphere/.env | patch ${MS_BASE}/metersphere/.env
ln -s ${MS_BASE}/metersphere/.env ${MS_BASE}/metersphere/install.conf
grep "127.0.0.1 $(hostname)" /etc/hosts >/dev/null || echo "127.0.0.1 $(hostname)" >> /etc/hosts
msctl generate_compose_files
msctl config 1>/dev/null 2>/dev/null
if [ $? != 0 ];then
   log "docker-compose 版本与配置文件不兼容，请重新安装最新版本的 docker-compose"
   exit
fi

export COMPOSE_HTTP_TIMEOUT=180
cd ${__current_dir}
# 加载镜像
if [[ -d images ]]; then
   log "加载镜像"
   for i in $(ls images); do
      docker load -i images/$i 2>&1 | tee -a ${__current_dir}/install.log
   done
else
   log "拉取镜像"
   msctl pull 2>&1 | tee -a ${__current_dir}/install.log
   docker pull ${MS_JMETER_IMAGE} 2>&1 | tee -a ${__current_dir}/install.log
   cd -
fi

log "启动服务"
msctl down -v 2>&1 | tee -a ${__current_dir}/install.log
msctl up -d 2>&1 | tee -a ${__current_dir}/install.log

msctl status 2>&1 | tee -a ${__current_dir}/install.log

echo -e "======================= 安装完成 =======================\n" 2>&1 | tee -a ${__current_dir}/install.log

echo -e "请通过以下方式访问:\n URL: http://\$LOCAL_IP:${MS_SERVER_PORT}\n 用户名: admin\n 初始密码: metersphere" 2>&1 | tee -a ${__current_dir}/install.log
echo -e "您可以使用命令 'msctl status' 检查服务运行情况.\n" 2>&1 | tee -a ${__current_dir}/install.log-a ${__current_dir}/install.log
