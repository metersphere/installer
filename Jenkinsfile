pipeline {
    agent {
        node {
            label 'metersphere'
        }
    }
    options { 
        quietPeriod(30)
        checkoutToSubdirectory('installer')
    }
    environment {
        BRANCH_NAME = "v1.18"
        IMAGE_PREFIX = "registry.cn-qingdao.aliyuncs.com/metersphere"
        JMETER_TAG = "5.4.3-ms2-jdk8"
    }
    stages {
        stage('Preparation') {
            steps {
                script {
                    RELEASE = ""
                    if (env.TAG_NAME != null) {
                        RELEASE = env.TAG_NAME
                    } else {
                        RELEASE = env.BRANCH_NAME
                    }
                    env.RELEASE = "${RELEASE}"
                    echo "RELEASE=${RELEASE}"
                }
            }
        }
        stage('Checkout') {
            when { tag "v*" }
            steps {
                // Get some code from a GitHub repository

                dir('ms-server') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere.git', branch: "${BRANCH_NAME}"
                }
                dir('ms-node-controller') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/node-controller.git', branch: "${BRANCH_NAME}"
                }
                dir('ms-data-streaming') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/data-streaming.git', branch: "${BRANCH_NAME}"
                }
                dir('jenkins-plugin') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/jenkins-plugin.git', branch: "${BRANCH_NAME}"
                }
                sh '''
                    git config --global user.email "wangzhen@fit2cloud.com"
                    git config --global user.name "BugKing"
                '''
            }
        }
        stage('Tag Other Repos') {
            when { tag "v*" }
            parallel {
                stage('ms-server') {
                    steps {
                        dir('ms-server') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
                stage('ms-node-controller') {
                    steps {
                        dir('ms-node-controller') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
                stage('ms-data-streaming') {
                    steps {
                        dir('ms-data-streaming') {
                            sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                            sh("git push -f origin refs/tags/${RELEASE}")
                        }
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
        stage('Modify install conf') {
            steps {
                dir('installer') {
                    sh '''
                        rm -rf metersphere-*.tar.gz
                        #修改安装参数
                        sed -i -e "s#MS_IMAGE_TAG=.*#MS_IMAGE_TAG=${RELEASE}#g" install.conf
                        sed -i -e "s#MS_IMAGE_PREFIX=.*#MS_IMAGE_PREFIX=${IMAGE_PREFIX}#g" install.conf
                        sed -i -e "s#MS_JMETER_IMAGE=.*#MS_JMETER_IMAGE=\\\${MS_IMAGE_PREFIX}/jmeter-master:${JMETER_TAG}#g" install.conf
                        echo ${RELEASE}-b$BUILD_NUMBER > ./metersphere/version                   
                    '''
                }
            }
        }
        stage('Package Online-install') {
            steps {
                dir('installer') {
                    sh '''          
                        #打包在线包
                        touch metersphere-online-installer-${RELEASE}.tar.gz
                        tar czvf metersphere-online-installer-${RELEASE}.tar.gz . --transform "s/^\\./metersphere-online-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude docker
                        #打包旧名称格式在线包
                        touch metersphere-release-${RELEASE}.tar.gz
                        tar czvf metersphere-release-${RELEASE}.tar.gz . --transform "s/^\\./metersphere-release-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude docker
                    '''
                }
            }
        }
        stage('Release') {
            when { tag "v*" }
            steps {
                withCredentials([string(credentialsId: 'gitrelease', variable: 'TOKEN')]) {
                    withEnv(["TOKEN=$TOKEN"]) {
                        dir('installer') {
                            sh script: '''
                                release=$(curl -XPOST -H "Authorization:token $TOKEN" --data "{\\"tag_name\\": \\"${RELEASE}\\", \\"target_commitish\\": \\"${BRANCH_NAME}\\", \\"name\\": \\"${RELEASE}\\", \\"body\\": \\"\\", \\"draft\\": false, \\"prerelease\\": true}" https://api.github.com/repos/metersphere/metersphere/releases)
                                id=$(echo "$release" | sed -n -e \'s/"id":\\ \\([0-9]\\+\\),/\\1/p\' | head -n 1 | sed \'s/[[:blank:]]//g\')
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @quick_start.sh https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=quick_start.sh
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-online-installer-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-online-installer-${RELEASE}.tar.gz
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-release-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-release-${RELEASE}.tar.gz
                            '''
                        }
                    }
                }
            }
        }        
        stage('Package Offline-install') {
            when { tag "v*" }
            steps {
                dir('installer') {
                    script {
                        def images = ['jmeter-master:${JMETER_TAG}',
                                    'kafka:2',
                                    'zookeeper:3',
                                    'mysql:5.7.33',
                                    'prometheus:latest',
                                    'standalone-chrome:4.1.1',
                                    'node-exporter:latest',
                                    "metersphere:${RELEASE}",
                                    "ms-node-controller:${RELEASE}",
                                    "ms-data-streaming:${RELEASE}"]
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
                        docker save ${IMAGE_PREFIX}/metersphere:${RELEASE} -o metersphere.tar
                        docker save ${IMAGE_PREFIX}/ms-node-controller:${RELEASE} -o ms-node-controller.tar
                        docker save ${IMAGE_PREFIX}/ms-data-streaming:${RELEASE} -o ms-data-streaming.tar
                        docker save ${IMAGE_PREFIX}/jmeter-master:${JMETER_TAG} -o jmeter-master.tar
                        docker save ${IMAGE_PREFIX}/kafka:2 -o kafka.tar
                        docker save ${IMAGE_PREFIX}/zookeeper:3 -o zookeeper.tar
                        docker save ${IMAGE_PREFIX}/mysql:5.7.33 -o mysql.tar
                        docker save ${IMAGE_PREFIX}/prometheus:latest -o prometheus.tar
                        docker save ${IMAGE_PREFIX}/node-exporter:latest -o node-exporter.tar
                        docker save ${IMAGE_PREFIX}/standalone-chrome:4.1.1 -o standalone-chrome.tar
                        cd ..

                        #获取docker
                        rm -rf docker*
                        wget http://fit2cloud2-offline-installer.oss-cn-beijing.aliyuncs.com/tools/docker.zip
                        unzip docker.zip
                        rm -rf __MACOSX
                        rm -rf docker.zip

                        #打包离线包
                        touch metersphere-offline-installer-${RELEASE}.tar.gz
                        tar czvf metersphere-offline-installer-${RELEASE}.tar.gz . --transform "s/^\\./metersphere-offline-installer-${RELEASE}/" \\
                            --exclude metersphere-online-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-offline-installer-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude .git

                        md5sum -b metersphere-offline-installer-${RELEASE}.tar.gz | awk '{print $1}' > metersphere-offline-installer-${RELEASE}.tar.gz.md5
                        rm -rf images
                    '''
                }
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'installer/*.tar.gz,installer/quick_start.sh,installer/*.md5', followSymlinks: false
            }
        }
        stage('Upload') {
            when { anyOf { tag pattern: "^v\\d+\\.\\d+\\.\\d+\$", comparator: "REGEXP";tag pattern: "^v\\d+\\.\\d+\\.\\d+-lts\$", comparator: "REGEXP"}}
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
                qyWechatNotification failSend: true, mentionedId: '', mentionedMobile: '', webhookUrl: "$WEBHOOK"
            }
        }
    }
}