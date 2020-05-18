#!/bin/bash
BASE_DIR=$(cd "$(dirname "$0")";pwd)
source ${BASE_DIR}/install_config.sh
action=$1
target=$2
args=$@

compose_files="-f docker-compose-base.yml"
#images = 

function usage() {
   echo "MeterSphere 部署安装脚本"
   echo
   echo "Usage: "
   echo "  ./msctl.sh [COMMAND] [ARGS...]"
   echo "  ./msctl.sh --help"
   echo
   echo "Commands: "
   echo "  install 部署安装 MeterSphere"
}

function install() {
   echo "== 开始安装 MeterSphere =="
   echo "... 拷贝资源至安装路径"
   cp -r ./metersphere $(install_config base_dir) && echo "... 拷贝资源至安装路径成功"
   echo "... 替换安装配置参数"
   for i in ${support_config};do
      key=${i}
      value=$(install_config $i)
      if [[ -n $key && -n $value ]];then
         sed -i -e "s#\${${key}}#${value}#g" $(install_config base_dir)/metersphere/conf/* $(install_config base_dir)/metersphere/bin/mysql/* $(install_config base_dir)/metersphere/docker-compose*
      fi
   done
   echo "... 配置安装模式"
   install_mode=$(install_config install_mode)
   case ${install_mode} in
      allinone)
         mkdir -p $(install_config base_dir)/metersphere/data/jmeter
         compose_files="${compose_files} -f docker-compose-server.yml -f docker-compose-node-controller.yml"
         ;;
      server)
         compose_files="${compose_files} -f docker-compose-server.yml" 
         ;;
      node-controller)
         mkdir -p $(install_config base_dir)/metersphere/data/jmeter
         compose_files="${compose_files} -f docker-compose-node-controller.yml" 
         ;;
      *)
         echo "... 不支持的安装模式，请从 [ allinone | server | node-controller ] 中进行选择"
   esac
   # 是否使用外部数据库
   if [ $(install_config external_mysql) = "false" ];then
      mkdir -p $(install_config base_dir)/metersphere/data/mysql
      compose_files="${compose_files} -f docker-compose-mysql.yml"
   else
      sed -i -e "/#external_mysql=false/{N;N;d;}" $(install_config base_dir)/metersphere/docker-compose*
   fi
   # 是否使用外部 Kafka
   if [ $(install_config external_kafka) = "false" ];then
      mkdir -p $(install_config base_dir)/metersphere/data/kafka
      mkdir -p $(install_config base_dir)/metersphere/data/zookeeper
      compose_files="${compose_files} -f docker-compose-kafka.yml" 
   else
      sed -i -e "/#external_kafka=false/{N;N;d;}" $(install_config base_dir)/metersphere/docker-compose*
   fi
   # TODO 加载镜像

   echo "... 启动 MeterSphere"
   echo ${compose_files}
   cd $(install_config base_dir)/metersphere && docker-compose ${compose_files} up -d
}

function status() {
   echo
}

function main() {
    case "${action}" in
      install)
         install
         ;;
      help)
         usage
         ;;
      --help)
         usage
         ;;
      *)
         echo "不支持的参数，请使用 help 或 --help 参数获取帮助"
    esac
}
main