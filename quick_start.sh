#!/bin/bash

#Install Latest Stable MeterSphere Release

python - <<EOF
# -*- coding: UTF-8 -*-
import os
import json
import re

latest_release=""
release_pattern="v\d+\.\d+\.\d+-lts$"

def get_releases(page):
  # 根据是否是LTS版本获取对应的最新版本号
  try:
      releases=os.popen("curl -s https://api.github.com/repos/metersphere/metersphere/releases?page=%d" % (page)).read()
      releases=[ x["name"] for x in json.loads(releases) if x["prerelease"] == False ]
  except Exception as e:
      print(str(e))
      print("获取Release信息失败，请检查服务器到GitHub的网络连接是否正常")
      exit(1)
  else:
      for release in releases:
          if re.search(release_pattern,release) != None:
            return release

page = 1
while (page <= 10):
  latest_release = get_releases(page)
  if (latest_release != "" and latest_release != None):
    break
  page += 1

# 记录最新版本号
os.popen("echo "+latest_release+" > /tmp/ms_latest_release")

EOF

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

wget --no-check-certificate ${DOWNLOAD_URL}
tar zxvf metersphere-online-installer-${MSVERSION}.tar.gz
cd metersphere-online-installer-${MSVERSION}

sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${MSVERSION}#g" install.conf
sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=registry.cn-qingdao.aliyuncs.com\/metersphere#g" install.conf

/bin/bash install.sh

