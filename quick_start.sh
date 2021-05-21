#Install Latest Stable MeterSphere Release

os=`uname -a`

# 支持MacOS
if [[ $os =~ 'Darwin' ]];then
    MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest |grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
else
	MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po 'v[0-9]+\.[0-9]+\.[0-9]+.*(?=")')
fi

wget --no-check-certificate https://github.com/metersphere/metersphere/releases/latest/download/metersphere-release-${MSVERSION}.tar.gz
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-release-${MSVERSION}.tar.gz
cd metersphere-release-${MSVERSION}

sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${MSVERSION}#g" install.conf
sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=registry.cn-qingdao.aliyuncs.com\/metersphere#g" install.conf

/bin/bash install.sh
