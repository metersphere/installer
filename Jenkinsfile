#!groovy

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
        JMETER_TAG = "5.6.3-release1"
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
                dir('task-runner') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/task-runner.git', branch: "${BRANCH_NAME}"
                }
                dir('result-hub') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/result-hub.git', branch: "${BRANCH_NAME}"
                }
                dir('metersphere-standalone') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere-standalone.git', branch: "${BRANCH_NAME}"
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
        stage('Tags All repo') {
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
                dir('task-runner') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('result-hub') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('jenkins-plugin') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                dir('metersphere-standalone') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                build job:"/刷新组织最新分支"
            }
        }
        stage('Build SDK') {
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
                            build job:"../metersphere/${RELEASE}", quietPeriod:10, parameters: [
                                string(name: 'buildSdk', value: "true"),
                            ]
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
        stage('Build Repos') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            parallel {
                stage('metersphere-xpack') {
                    steps {
                      
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../metersphere-xpack/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../metersphere-xpack/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('task-runner') {
                    steps {
                       
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../task-runner/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../task-runner/${RELEASE} as it doesn't exist")
                                    continue
                                }
                            }
                        }
                    }
                }
                stage('result-hub') {
                    steps {
                        script {
                            for (int i=0;i<10;i++) {
                                try {
                                    echo "Waiting for scanning new created Job"
                                    sleep 10
                                    build job:"../result-hub/${RELEASE}", quietPeriod:10
                                    break
                                } catch (Exception e) {
                                    println("Not building the job ../result-hub/${RELEASE} as it doesn't exist")
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
        stage('metersphere') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
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
        stage('metersphere-standalone') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                script {
                    for (int i=0;i<10;i++) {
                        try {
                            echo "Waiting for scanning new created Job"
                            sleep 10
                            build job:"../metersphere-standalone/${RELEASE}", quietPeriod:10
                            break
                        } catch (Exception e) {
                            println(e)
                            println("Not building the job ../metersphere-standalone/${RELEASE} as it doesn't exist")
                            continue
                        }
                    }
                }
            }
        }
        stage('Modify install conf') {
            when {
                anyOf {
                    tag pattern: "^v.*", comparator: "REGEXP"
                }
            }
            steps {
                dir('installer') {
                    sh '''
                        rm -rf metersphere-*.tar.gz
                        #修改安装参数
                        sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${RELEASE}#g" install.conf
                        sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=${IMAGE_PREFIX}#g" install.conf
                        echo ${RELEASE} > ./metersphere/version                   
                    '''
                }
            }
        }
        stage('Package Online-install') {
            when {
                anyOf {
                    tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP";
                }
            }
            steps {
                dir('installer') {
                    sh '''          
                        #打包社区版在线包
                        touch metersphere-ce-online-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-ce-online-installer-${RELEASE}/" \\
                            --exclude metersphere-ce-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude community \\
                            --exclude enterprise \\
                            --exclude docker \\
                            -czvf metersphere-ce-online-installer-${RELEASE}.tar.gz .

              
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
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-ce-online-installer-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-ce-online-installer-${RELEASE}.tar.gz

                                ossutil -c /opt/jenkins-home/metersphere/config cp -f metersphere-ce-online-installer-${RELEASE}.tar.gz oss://resource-fit2cloud-com/metersphere/metersphere/releases/download/${RELEASE}/ --update
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
                        def images = ['mysql:8.0.36',
                                    'kafka:3.7.0',
                                    'redis:7.2.4-alpine',
                                    'minio:RELEASE.2024-02-17T01-15-57Z',
                                    // 'jmeter:${JMETER_TAG}',
                                    // 'prometheus:v2.42.0',
                                    // 'node-chromium:4.18.0',
                                    // 'node-firefox:4.18.0',
                                    // 'selenium-hub:4.18.0',
                                    "metersphere-ce:${RELEASE}",
                                    "metersphere-ee:${RELEASE}"
                                    ]
                        for (image in images) {
                            waitUntil {
                                def r = sh script: "docker pull ${IMAGE_PREFIX}/${image}", returnStatus: true
                                r == 0;
                            }
                        }
                    }
                    sh '''
                        #保存社区版镜像
                        rm -rf images && mkdir images && cd images
                        docker save ${IMAGE_PREFIX}/metersphere-ce:${RELEASE} \\
                        ${IMAGE_PREFIX}/kafka:3.7.0 \\
                        ${IMAGE_PREFIX}/mysql:8.0.36 \\
                        ${IMAGE_PREFIX}/redis:7.2.4-alpine \\
                        ${IMAGE_PREFIX}/minio:RELEASE.2024-02-17T01-15-57Z > metersphere.tar
                        cd ..

                        #保存企业版镜像
                        rm -rf enterprise && mkdir enterprise && cd enterprise
                        docker save ${IMAGE_PREFIX}/metersphere-ee:${RELEASE} \\
                        ${IMAGE_PREFIX}/kafka:3.7.0 \\
                        ${IMAGE_PREFIX}/mysql:8.0.36 \\
                        ${IMAGE_PREFIX}/redis:7.2.4-alpine \\
                        ${IMAGE_PREFIX}/minio:RELEASE.2024-02-17T01-15-57Z > metersphere.tar 
                        # ${IMAGE_PREFIX}/jmeter:${JMETER_TAG} \\
                        # ${IMAGE_PREFIX}/prometheus:v2.42.0 \\
                        # ${IMAGE_PREFIX}/node-firefox:4.18.0 \\
                        # ${IMAGE_PREFIX}/node-chromium:4.18.0 \\
                        # ${IMAGE_PREFIX}/selenium-hub:4.18.0 
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

                        #打包社区版离线包
                        touch metersphere-ce-offline-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-ce-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-ce-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude enterprise \\
                            -czvf metersphere-ce-offline-installer-${RELEASE}.tar.gz .

                        md5sum -b metersphere-ce-offline-installer-${RELEASE}.tar.gz | awk '{print $1}' > metersphere-ce-offline-installer-${RELEASE}.tar.gz.md5
                        rm -rf images
                        
                        mv enterprise images
                        #打包企业版离线包
                        sed -i -e "s#-ce#-ee#g" metersphere/docker-compose-metersphere.yml
                        sed -i -e "s#-ce#-ee#g" metersphere/docker-compose-task-runner.yml
                        sed -i -e "s#-ce#-ee#g" metersphere/docker-compose-result-hub.yml

                        # 部分配置只有企业版包有
                        echo '# 企业版配置' >> install.conf
                        echo '# Prometheus 配置' >> install.conf
                        echo '## 是否使用外部Prometheus' >> install.conf
                        echo 'MS_EXTERNAL_PROM=false' >> install.conf
                        echo 'MS_PROMETHEUS_PORT=9090' >> install.conf
                        echo '## 是否使用企业版' >> install.conf
                        echo 'MS_ENTERPRISE_ENABLE=false' >> install.conf
                        echo '# UI容器配置' >> install.conf
                        echo '## 是否使用外部grid' >> install.conf
                        echo 'MS_EXTERNAL_SELENIUM=false' >> install.conf
                        echo '## 性能测试使用的 JMeter 镜像' >> install.conf
                        echo "MS_JMETER_IMAGE=${MS_IMAGE_PREFIX}/${JMETER_TAG}" >> install.conf
                        echo '## docker gid' >> install.conf
                        echo 'MS_DOCKER_GID=$(getent group docker | cut -f3 -d:)' >> install.conf
                        
                        rm -rf metersphere/*.yml-e
                        
                        touch metersphere-ee-offline-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-ee-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-ee-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-ce-offline-installer-${RELEASE}.tar.gz.md5 \\
                            --exclude .git \\
                            -czvf metersphere-ee-offline-installer-${RELEASE}.tar.gz .

                        md5sum -b metersphere-ee-offline-installer-${RELEASE}.tar.gz | awk '{print $1}' > metersphere-ee-offline-installer-${RELEASE}.tar.gz.md5
                        rm -rf images
                    '''
                }
            }
        }
        stage('Upload') {
            when {
                anyOf {
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-alpha\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-alpha-arm64\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-beta\$", comparator: "REGEXP";
                    tag pattern: "^v\\d+\\.\\d+\\.\\d+-beta-arm64\$", comparator: "REGEXP";

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
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-ce-offline-installer-${RELEASE}.tar.gz ./metersphere-ce-offline-installer-${RELEASE}.tar.gz")
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-ce-offline-installer-${RELEASE}.tar.gz.md5 ./metersphere-ce-offline-installer-${RELEASE}.tar.gz.md5")

                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-ee-offline-installer-${RELEASE}.tar.gz ./metersphere-ee-offline-installer-${RELEASE}.tar.gz")
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-ee-offline-installer-${RELEASE}.tar.gz.md5 ./metersphere-ee-offline-installer-${RELEASE}.tar.gz.md5")
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