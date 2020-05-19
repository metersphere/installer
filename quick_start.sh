#Install docker & docker-compose
##Install Latest Stable Docker Release
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
service docker start
echo "Docker Installation done"

##Install Latest Stable Docker Compose Release
COMPOSEVERSION=$(curl -s https://github.com/docker/compose/releases/latest/download 2>&1 | grep -Po [0-9]+\.[0-9]+\.[0-9]+)
curl -L "https://github.com/docker/compose/releases/download/$COMPOSEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
echo "Docker Compose Installation done"

#Install Latest Stable MeterSphere Release
#MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po [0-9]+\.[0-9]+\.[0-9]+)
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-release-${MSVERSION}.tar.gz
cd metersphere-release-${MSVERSION}
echo "metersphere_image_tag=${MSVERSION}" > install.conf
./msctl.sh install
echo -e "MeterSphere Installation Complete \n\nLogin to your MeterSphere instance:\n URL: http://$LOCAL_IP:8081\n Username: admin Password: fit2cloud"