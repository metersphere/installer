#!/bin/bash
BASE_DIR=$(cd "$(dirname "$0")";pwd)
# source ${BASE_DIR}/scripts/utils.sh
action=$1
target=$2
args=$@

# 加载安装配置参数
. ./install.conf.default
[ -f install.conf ] && . ./install.conf
compose_files="-f docker-compose-base.yml"

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

function generate_install_conf() {
   if [ -f ./install.conf ];then
      echo "== 发现安装配置文件，加载并合并配置"
      echo "== 最终配置为"
      install_conf=$(awk -F= '!a[$1]++' install.conf install.conf.default | grep -v -e \^\\s\*\#)
      for i in ${install_conf};do
         echo ${i}
      done
   else
      install_conf=$(cat install.conf.default)
   fi
}

function install() {
   echo "= 开始安装 MeterSphere"
   echo "== 生成安装配置"
   generate_install_conf
   echo "== 拷贝资源至安装路径"
   cp -r ./metersphere ${base_dir} && echo "拷贝资源至安装路径成功"
   echo "== 装配安装配置参数"
   for i in ${install_conf};do
      key=${i%%=*}
      value=${i##*=}
      if [[ -n $key && -n $value ]];then
         sed -i -e "s#\${${key}}#${value}#g" ${base_dir}/metersphere/conf/* ${base_dir}/metersphere/bin/mysql/* ${base_dir}/metersphere/docker-compose*
      fi
   done
   echo "== 配置安装模式"
   case "${install_mode}" in
      allinone)
         compose_files="${compose_files} -f dockser-compose-server.yml -f docker-compose-node-controller.yml"
         ;;
      server)
         compose_files="${compose_files} -f dockser-compose-server.yml" 
         ;;
      node-controller)
         compose_files="${compose_files} -f dockser-compose-node-controller.yml" 
         ;;
      *)
         echo "不支持的安装模式，请从 [ allinone | server | node-controller ] 中进行选择"
   esac
   if [ "$external_mysql" = "false" ];then
      compose_files="${compose_files} -f dockser-compose-mysql.yml" 
   fi
   if [ "$external_kafka" = "false" ];then
      compose_files="${compose_files} -f dockser-compose-kafka.yml" 
   fi
   echo "== 启动 MeterSphere"
   cd ${base_dir}/metersphere && docker-compose ${compose_files} up -d
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
install