#Install docker & docker-compose
##Install Latest Stable Docker Release
if which docker;then
    echo "Docker already installed, skip installation"
else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    service docker start
    echo "Docker Installation done"
fi

##Install Latest Stable Docker Compose Release
if which docker-compose;then
    echo "Docker Compose already installed, skip installation"
else
    COMPOSEVERSION=$(curl -s https://github.com/docker/compose/releases/latest/download 2>&1 | grep -Po [0-9]+\.[0-9]+\.[0-9]+)
    curl -L "https://github.com/docker/compose/releases/download/$COMPOSEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose Installation done"
fi

#Install Latest Stable MeterSphere Release
#MSVERSION=$(curl -s https://github.com/metersphere/metersphere/releases/latest/download 2>&1 | grep -Po v[0-9]+\.[0-9]+\.[0-9]+)
#curl -s https://api.github.com/repos/metersphere/metersphere/releases/latest | grep browser_download_url | grep online | cut -d '"' -f 4 | wget -qi -
tar zxvf metersphere-release-${MSVERSION}.tar.gz
cd metersphere-release-${MSVERSION}
echo "MS_TAG=${MSVERSION}" > install.conf
echo "MS_PREFIX=metersphere" >> install.conf
sh install.sh
msctl status
echo -e "MeterSphere Installation Complete \n\nLogin to your MeterSphere instance:\n URL: http://$LOCAL_IP:8081\n Username: admin Password: fit2cloud"
echo -e "You can use command 'msctl status' to check the status of MeterSphere."