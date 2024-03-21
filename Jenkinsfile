pipeline {
    agent {
        node {
            label params.label == "" ? "metersphere" : params.label
        }
    }
    options {
        checkoutToSubdirectory('installer')
    }
    environment {
        IMAGE_PREFIX = "registry.cn-qingdao.aliyuncs.com/metersphere"
        JMETER_TAG = "5.5-ms10-jdk17"
    }
    stages {
        stage('Preparation') {
            steps {
                script {
                    if (params.branch != null) {
                        env.BRANCH_NAME = params.branch
                    }
                    if (params.release != null) {
                        env.RELEASE = params.release.replace("-arm64", "")
                    } else {
                        env.RELEASE = env.BRANCH_NAME
                    }

                    echo "RELEASE=${RELEASE}"
                    echo "BRANCH=${BRANCH_NAME}"
                }
            }
        }
        stage('Checkout') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                // Get some code from a GitHub repository

                dir('metersphere') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere.git', branch: "${BRANCH_NAME}"
                }
                dir('metersphere-xpack') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere-xpack.git', branch: "${BRANCH_NAME}"
                }
                dir('ui-test') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/ui-test.git', branch: "${BRANCH_NAME}"
                }
                dir('node-controller') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/node-controller.git', branch: "${BRANCH_NAME}"
                }
                dir('data-streaming') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/data-streaming.git', branch: "${BRANCH_NAME}"
                }
                dir('jenkins-plugin') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/jenkins-plugin.git', branch: "${BRANCH_NAME}"
                }
                sh '''
                    git config --global user.email "metersphere@fit2cloud.com"
                    git config --global user.name "metersphere-bot"
                '''
            }
        }
        stage('Tags All Repos') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                dir('metersphere') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('metersphere-xpack') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('ui-test') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('node-controller') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('data-streaming') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('jenkins-plugin') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                build job:"/刷新组织最新分支"
            }
        }

        stage('MS Domain SDK XPack') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                script {
                    REVISION = ""
                    if (env.RELEASE.startsWith("v") ) {
                        REVISION = env.RELEASE.substring(1)
                    } else {
                        REVISION = env.RELEASE
                    }
                    env.REVISION = "${REVISION}"
                    echo "REVISION=${REVISION}"
                }
             
                script {
                    for (int i=0;i<10;i++) {
                        try {
                            echo "Waiting for scanning new created Job"
                            sleep 10
                            build job:"../metersphere-xpack/${RELEASE}", quietPeriod:10
                            break
                        } catch (Exception e) {
                            println(e)
                            println("Not building the job ../metersphere-xpack/${RELEASE} as it doesn't exist")
                            continue
                        }
                    }
                }
            }
        }

        stage('Tag Other Repos') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            parallel {
                stage('metersphere') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../metersphere/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println(e)
                                    println("Not building the job ../metersphere/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('ui-test') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../ui-test/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../ui-test/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('node-controller') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../node-controller/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../node-controller/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('data-streaming') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../data-streaming/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../data-streaming/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('jenkins-plugin') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../jenkins-plugin/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../jenkins-plugin/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Modify install conf') {
            when {
                anyOf {
                    tag pattern: "^v.*", comparator: "REGEXP"
                    tag "dev"
                    tag "main"
                }
            }
            steps {
                dir('installer') {
                    sh '''
                        rm -rf metersphere-*.tar.gz
                        #修改安装参数
                        sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${RELEASE}#g" install.conf
                        sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=${IMAGE_PREFIX}#g" install.conf
                        sed -i -e "s#MS_JMETER_IMAGE=.*#MS_JMETER_IMAGE=\\\${MS_IMAGE_PREFIX}/jmeter-master:${JMETER_TAG}#g" install.conf
                        echo ${RELEASE} > ./metersphere/version                   
                    '''
                }
            }
        }
        stage('Package Online-install') {
            when {
                anyOf {
                    tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP";
                    tag "dev"
                    tag "main"
                }
            }
            steps {
                dir('installer') {
                    sh '''          
                        #打包在线包
                        touch metersphere-online-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-online-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude docker \\
                            -czvf metersphere-online-installer-${RELEASE}.tar.gz .
                    '''
                }
            }
        }
        stage('Release') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                withCredentials([string(credentialsId: 'gitrelease', variable: 'TOKEN'), string(credentialsId: 'HTTPS_PROXY', variable: 'HTTPS_PROXY')]) {
                    withEnv(["TOKEN=$TOKEN", "HTTPS_PROXY=$HTTPS_PROXY"]) {
                        dir('installer') {
                            sh script: '''
                                release=$(curl -XPOST -H "Authorization:token $TOKEN" --data "{\\"tag_name\\": \\"${RELEASE}\\", \\"target_commitish\\": \\"${BRANCH_NAME}\\", \\"name\\": \\"${RELEASE}\\", \\"body\\": \\"\\", \\"draft\\": false, \\"prerelease\\": true}" https://api.github.com/repos/metersphere/metersphere/releases)
                                id=$(echo "$release" | sed -n -e \'s/"id":\\ \\([0-9]\\+\\),/\\1/p\' | head -n 1 | sed \'s/[[:blank:]]//g\')
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @quick_start.sh https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=quick_start.sh
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-online-installer-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-online-installer-${RELEASE}.tar.gz

                                ossutil -c /opt/jenkins-home/metersphere/config cp -f metersphere-online-installer-${RELEASE}.tar.gz oss://resource-fit2cloud-com/metersphere/metersphere/releases/download/${RELEASE}/ --update
                                ossutil -c /opt/jenkins-home/metersphere/config cp -f quick_start.sh oss://resource-fit2cloud-com/metersphere/metersphere/releases/download/${RELEASE}/quick_start.sh --update
                                ossutil -c /opt/jenkins-home/metersphere/config cp -f quick_start.sh oss://resource-fit2cloud-com/metersphere/metersphere/releases/latest/download/quick_start.sh --update
                            '''
                        }
                    }
                }
            }
        }        
        stage('Package Offline-install') {
            when { tag pattern: "^v.*", comparator: "REGEXP" }
            steps {
                dir('installer') {
                    script {
                        def images = ['jmeter-master:${JMETER_TAG}',
                                    'kafka:3.6.1',
                                    'mysql:8.0.35',
                                    'redis:6.2.6',
                                    'minio:RELEASE.2023-04-13T03-08-07Z',
                                    'prometheus:v2.42.0',
                                    'node-chromium:4.10.0',
                                    'node-firefox:4.10.0',
                                    'selenium-hub:4.10.0',
                                    "api-test:${RELEASE}",
                                    "performance-test:${RELEASE}",
                                    "project-management:${RELEASE}",
                                    "report-stat:${RELEASE}",
                                    "system-setting:${RELEASE}",
                                    "test-track:${RELEASE}",
                                    "ui-test:${RELEASE}",
                                    "workstation:${RELEASE}",
                                    "gateway:${RELEASE}",
                                    "eureka:${RELEASE}",
                                    "node-controller:${RELEASE}",
                                    "data-streaming:${RELEASE}"]
                        for (image in images) {
                            waitUntil {
                                def r = sh script: "docker pull ${IMAGE_PREFIX}/${image}", returnStatus: true
                                r == 0;
                            }
                        }
                    }
                    sh '''
                        #保存镜像
                        rm -rf images && mkdir images && cd images
                        docker save ${IMAGE_PREFIX}/api-test:${RELEASE} \\
                        ${IMAGE_PREFIX}/performance-test:${RELEASE} \\
                        ${IMAGE_PREFIX}/project-management:${RELEASE} \\
                        ${IMAGE_PREFIX}/report-stat:${RELEASE} \\
                        ${IMAGE_PREFIX}/system-setting:${RELEASE} \\
                        ${IMAGE_PREFIX}/test-track:${RELEASE} \\
                        ${IMAGE_PREFIX}/ui-test:${RELEASE} \\
                        ${IMAGE_PREFIX}/workstation:${RELEASE} \\
                        ${IMAGE_PREFIX}/gateway:${RELEASE} \\
                        ${IMAGE_PREFIX}/eureka:${RELEASE} \\
                        ${IMAGE_PREFIX}/node-controller:${RELEASE} \\
                        ${IMAGE_PREFIX}/data-streaming:${RELEASE} \\
                        ${IMAGE_PREFIX}/jmeter-master:${JMETER_TAG} \\
                        ${IMAGE_PREFIX}/kafka:3.6.1 \\
                        ${IMAGE_PREFIX}/mysql:8.0.35 \\
                        ${IMAGE_PREFIX}/redis:6.2.6 \\
                        ${IMAGE_PREFIX}/minio:RELEASE.2023-04-13T03-08-07Z \\
                        ${IMAGE_PREFIX}/prometheus:v2.42.0 \\
                        ${IMAGE_PREFIX}/node-firefox:4.10.0 \\
                        ${IMAGE_PREFIX}/node-chromium:4.10.0 \\
                        ${IMAGE_PREFIX}/selenium-hub:4.10.0 > metersphere.tar
                        cd ..
                    '''
                    script {
                        // 区分不同架构
                        RELEASE = ""
                        ARCH = "x86_64"
                        if (env.TAG_NAME != null) {
                            RELEASE = env.TAG_NAME
                            if (RELEASE.endsWith("-arm64")) {
                                ARCH = "aarch64"
                            }
                        } else {
                            RELEASE = env.BRANCH_NAME
                        }
                        env.RELEASE = "${RELEASE}"
                        env.ARCH = "${ARCH}"
                        echo "RELEASE=${RELEASE}"
                        echo "ARCH=${ARCH}"
                    }
                    sh '''
                        #获取docker
                        rm -rf docker/*
                        rm -rf docker

                        wget https://resource.fit2cloud.com/docker/download/${ARCH}/docker-25.0.2.tgz
                        wget https://resource.fit2cloud.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-${ARCH} && mv docker-compose-linux-${ARCH} docker-compose && chmod +x docker-compose
                        tar -zxvf docker-25.0.2.tgz
                        rm -rf docker-25.0.2.tgz
                        mv docker bin && mkdir docker && mv bin docker/
                        mv docker-compose docker/bin
                        mkdir docker/service && mv docker.service docker/service/

                        #打包离线包
                        touch metersphere-offline-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            -czvf metersphere-offline-installer-${RELEASE}.tar.gz .

                        md5sum -b metersphere-offline-installer-${RELEASE}.tar.gz | awk '{print $1}' > metersphere-offline-installer-${RELEASE}.tar.gz.md5
                        rm -rf images
                    '''
                }
            }
        }
        stage('Upload') {
            when {
                anyOf {
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-arm64\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-lts\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-lts-arm64\$", comparator: "REGEXP"
                }
            }
            steps {
                dir('installer') {
                    echo "UPLOADING"
                    withCredentials([usernamePassword(credentialsId: 'OSSKEY', passwordVariable: 'SK', usernameVariable: 'AK')]) {
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-offline-installer-${RELEASE}.tar.gz ./metersphere-offline-installer-${RELEASE}.tar.gz")
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-offline-installer-${RELEASE}.tar.gz.md5 ./metersphere-offline-installer-${RELEASE}.tar.gz.md5")
                    }
                }
            }
        }
    }
    post('Notification') {
        always {
            withCredentials([string(credentialsId: 'wechat-bot-webhook', variable: 'WEBHOOK')]) {
                qyWechatNotification failNotify: true, mentionedId: '', mentionedMobile: '', webhookUrl: "$WEBHOOK"
            }
        }
    }
}