#Install Latest Stable MeterSphere Release
MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po v[0-9]+\.[0-9]+\.[0-9]+)
wget https://github.com/metersphere/metersphere/releases/latest/download/metersphere-release-${MSVERSION}.tar.gz
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-release-${MSVERSION}.tar.gz
cd metersphere-release-${MSVERSION}
sed -i -e "s\MS_TAG=.*\MS_TAG=${MSVERSION}\g" install.conf
sed -i -e "s\MS_PREFIX=.*\MS_PREFIX=registry.cn-qingdao.aliyuncs.com/metersphere\g" install.conf
sh install.sh
msctl status
echo -e "MeterSphere Installation Complete \n\nLogin to your MeterSphere instance:\n URL: http://\$LOCAL_IP:${MS_PORT}\n Username: admin Password: metersphere"
echo -e "You can use command 'msctl status' to check the status of MeterSphere."