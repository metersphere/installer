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
        JMETER_TAG = "5.6.2-release1"
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
                dir('metersphere-community') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere-community.git', branch: "${BRANCH_NAME}"
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
                dir('metersphere') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
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

        stage('Tag Other Repos') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            parallel {
                stage('metersphere-xpack') {
                    steps {
                        dir('metersphere-xpack') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
                        dir('task-runner') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
                        dir('result-hub') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
                        dir('jenkins-plugin') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
        stage('metersphere-community') {
            when { tag pattern: "^v.*?(?<!-arm64)\$", comparator: "REGEXP" }
            steps {
                dir('metersphere-community') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin refs/tags/${RELEASE}")
                }
                script {
                    for (int i=0;i<10;i++) {
                        try {
                            echo "Waiting for scanning new created Job"
                            sleep 10
                            build job:"../metersphere-community/${RELEASE}", quietPeriod:10
                            break
                        } catch (Exception e) {
                            println(e)
                            println("Not building the job ../metersphere-community/${RELEASE} as it doesn't exist")
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
                        sed -i -e "s#MS_JMETER_IMAGE=.*#MS_JMETER_IMAGE=\\\${MS_IMAGE_PREFIX}/jmeter:${JMETER_TAG}#g" install.conf
                        echo ${RELEASE}-b$BUILD_NUMBER > ./metersphere/version                   
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
                        touch metersphere-community-online-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-community-online-installer-${RELEASE}/" \\
                            --exclude metersphere-community-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude community \\
                            --exclude docker \\
                            -czvf metersphere-community-online-installer-${RELEASE}.tar.gz .

                        #打包企业版在线包
                        touch metersphere-online-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-online-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-release-${RELEASE}.tar.gz \\
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
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-community-online-installer-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-community-online-installer-${RELEASE}.tar.gz
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-online-installer-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-online-installer-${RELEASE}.tar.gz

                                ossutil -c /opt/jenkins-home/metersphere/config cp -f metersphere-community-online-installer-${RELEASE}.tar.gz oss://resource-fit2cloud-com/metersphere/metersphere/releases/download/${RELEASE}/ --update
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
                        def images = ['jmeter:${JMETER_TAG}',
                                    'kafka:3.5.1',
                                    'mysql:8.0.35',
                                    'redis:7.2.0-alpine',
                                    'minio:RELEASE.2023-08-09T23-30-22Z',
                                    'prometheus:v2.42.0',
                                    'node-chromium:4.10.0',
                                    'node-firefox:4.10.0',
                                    'selenium-hub:4.10.0',
                                    "metersphere-community:${RELEASE}"
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
                        rm -rf community && mkdir community && cd community
                        docker save ${IMAGE_PREFIX}/metersphere-community:${RELEASE} \\
                        ${IMAGE_PREFIX}/kafka:3.5.1 \\
                        ${IMAGE_PREFIX}/mysql:8.0.35 \\
                        ${IMAGE_PREFIX}/redis:7.2.0-alpine \\
                        ${IMAGE_PREFIX}/minio:RELEASE.2023-08-09T23-30-22Z > metersphere.tar
                        cd ..

                        #保存企业版镜像
                        rm -rf images && mkdir images && cd images
                        docker save ${IMAGE_PREFIX}/metersphere-community:${RELEASE} \\
                        ${IMAGE_PREFIX}/jmeter:${JMETER_TAG} \\
                        ${IMAGE_PREFIX}/kafka:3.5.1 \\
                        ${IMAGE_PREFIX}/mysql:8.0.35 \\
                        ${IMAGE_PREFIX}/redis:7.2.0-alpine \\
                        ${IMAGE_PREFIX}/minio:RELEASE.2023-08-09T23-30-22Z \\
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

                        wget https://resource.fit2cloud.com/docker/download/${ARCH}/docker-23.0.1.tgz
                        wget https://resource.fit2cloud.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-${ARCH} && mv docker-compose-linux-${ARCH} docker-compose && chmod +x docker-compose
                        tar -zxvf docker-23.0.1.tgz
                        rm -rf docker-23.0.1.tgz
                        mv docker bin && mkdir docker && mv bin docker/
                        mv docker-compose docker/bin
                        mkdir docker/service && mv docker.service docker/service/

                        #打包社区版离线包
                        touch metersphere-community-offline-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-community-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-community-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            -czvf metersphere-community-offline-installer-${RELEASE}.tar.gz .

                        md5sum -b metersphere-community-offline-installer-${RELEASE}.tar.gz | awk '{print $1}' > metersphere-community-offline-installer-${RELEASE}.tar.gz.md5
                        rm -rf community

                        #打包企业版离线包
                        touch metersphere-offline-installer-${RELEASE}.tar.gz
                        tar --transform "s/^\\./metersphere-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-community-release-${RELEASE}.tar.gz \\
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
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-community-offline-installer-${RELEASE}.tar.gz ./metersphere-community-offline-installer-${RELEASE}.tar.gz")
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-community-offline-installer-${RELEASE}.tar.gz.md5 ./metersphere-community-offline-installer-${RELEASE}.tar.gz.md5")

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