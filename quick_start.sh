#!/bin/bash

#Install Latest Stable MeterSphere Release


latest_release=""
release_pattern="v[0-9]+\.[0-9]+\.[0-9]+-lts$"

function get_releases() {
    local page=$1
    # 根据是否是LTS版本获取对应的最新版本号
    releases=$(curl -s "https://api.github.com/repos/metersphere/metersphere/releases?page=${page}")
    releases=$(echo "${releases}" | grep -o '"name": "[^"]*' | awk -F '[:"]' '{print $5}' | grep '^v')
    
    for release in ${releases}; do
        if [[ "${release}" =~ ${release_pattern} ]]; then
            echo "${release}"
            return
        fi
    done
}

page=1
while [ ${page} -le 10 ]; do
    latest_release=$(get_releases ${page})
    if [ -n "${latest_release}" ]; then
        break
    fi
    ((page++))
done

# 记录最新版本号
echo "${latest_release}" > /tmp/ms_latest_release

MSVERSION=$(cat /tmp/ms_latest_release)
os=`uname -a`

git_urls=('github.com' 'resource.fit2cloud.com' 'hub.fastgit.org' 'ghproxy.com/https://github.com')

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

DOWNLOAD_URL="https://${server_url}/metersphere/metersphere/releases/download/${MSVERSION}/metersphere-online-installer-${MSVERSION}.tar.gz"
if [[ "${MSVERSION}" = "v3"* ]]; then
  DOWNLOAD_URL="https://${server_url}/metersphere/metersphere/releases/download/${MSVERSION}/metersphere-community-online-installer-${MSVERSION}.tar.gz"
fi


wget --no-check-certificate ${DOWNLOAD_URL}
if [[ "${MSVERSION}" = "v3"* ]]; then
  tar zxvf metersphere-community-online-installer-${MSVERSION}.tar.gz
  cd metersphere-community-online-installer-${MSVERSION}
else
  tar zxvf metersphere-online-installer-${MSVERSION}.tar.gz
  cd metersphere-online-installer-${MSVERSION}
fi

sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${MSVERSION}#g" install.conf
sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=registry.cn-qingdao.aliyuncs.com\/metersphere#g" install.conf

/bin/bash install.sh

