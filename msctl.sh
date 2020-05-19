# TODO
## 增加单独的 install.sh 脚本
## 安装完成后拷贝 msctl 到 bin 目录, 作为或许升级、重启等命令控制脚本
#!/bin/bash
action=$1
target=$2
args=$@

compose_files="-f docker-compose-base.yml"
#images = 

function usage() {
   echo "MeterSphere 控制脚本"
   echo
   echo "Usage: "
   echo "  ./msctl.sh [COMMAND] [ARGS...]"
   echo "  ./msctl.sh --help"
   echo
   echo "Commands: "
   echo "  status    查看 MeterSphere 服务运行状态"
   echo "  start     启动 MeterSphere 服务运行状态"
   echo "  stop      停止 MeterSphere 服务"
   echo "  restart   重启 MeterSphere 服务"
   echo "  uninstall 卸载 MeterSphere 服务运行状态"
   echo "  version   查看 MeterSphere 版本信息"
}

function status() {
   echo
}
function start() {
   echo
}
function stop() {
   echo
}
function restart() {
   echo
}
function uninstall() {
   echo
}
function version() {
   echo
}

function main() {
    case "${action}" in
      status)
         status
         ;;
      start)
         start
         ;;
      stop)
         stop
         ;;
      restart)
         restart
         ;;
      uninstall)
         uninstall
         ;;
      version)
         version
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