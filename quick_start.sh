#!/bin/bash

#Install Latest Stable MeterSphere Release

os=`uname -a`

git_urls=('github.com' 'hub.fastgit.org')

for git_url in ${git_urls[*]}
do
	success="true"
	for i in {1..3}
	do
		echo -ne "检测 ${git_url} ... ${i} "
	    curl -m 5 -kIs https://${git_url} >/dev/null
		if [ $? != 0 ];then
			echo "failed"
			success="false"
			break
		else
			echo "ok"
		fi
	done
	if [ ${success} == "true" ];then
		server_url=${git_url}
		break
	fi
done

if [ "x${server_url}" == "x" ];then
    echo "没有找到稳定的下载服务器，请稍候重试"
    exit 1
fi


echo "使用下载服务器 ${server_url}"

# 支持MacOS
if [[ $os =~ 'Darwin' ]];then
    MSVERSION=$(curl -s https://${server_url}/metersphere/metersphere/releases/latest |grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')
else
	MSVERSION=$(curl -s https://${server_url}/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po 'v[0-9]+\.[0-9]+\.[0-9]+.*(?=")')
fi

wget --no-check-certificate https://${server_url}/metersphere/metersphere/releases/latest/download/metersphere-online-installer-${MSVERSION}.tar.gz
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-online-installer-${MSVERSION}.tar.gz
cd metersphere-online-installer-${MSVERSION}

sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${MSVERSION}#g" install.conf
sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=registry.cn-qingdao.aliyuncs.com\/metersphere#g" install.conf

/bin/bash install.sh
