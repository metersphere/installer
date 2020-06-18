#Install Latest Stable MeterSphere Release

os=`uname -a`

# 支持MacOS
if [[ $os =~ 'Darwin' ]];then
    MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest |grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
else
	MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po 'v[0-9]+\.[0-9]+\.[0-9]+.*(?=")')
fi

wget https://github.com/metersphere/metersphere/releases/latest/download/metersphere-release-${MSVERSION}.tar.gz
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-release-${MSVERSION}.tar.gz
cd metersphere-release-${MSVERSION}

# SYSTEM_SEPARATOR: 操作系统路径分隔符
if [[ $os =~ 'Darwin' ]];then
	SYSTEM_SEPARATOR='/'
else
	SYSTEM_SEPARATOR='\'
fi

sed -i -e "s${SYSTEM_SEPARATOR}MS_TAG=.*${SYSTEM_SEPARATOR}MS_TAG=${MSVERSION}${SYSTEM_SEPARATOR}g" install.conf
sed -i -e "s${SYSTEM_SEPARATOR}MS_PREFIX=.*${SYSTEM_SEPARATOR}MS_PREFIX=registry.cn-qingdao.aliyuncs.com\/metersphere${SYSTEM_SEPARATOR}g" install.conf


/bin/bash install.sh
