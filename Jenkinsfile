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
        BRANCH_NAME = "v1.8"
        IMAGE_PREFIX = "registry.cn-qingdao.aliyuncs.com/metersphere"
        JMETER_TAG = "5.4.1-ms3-jdk8"
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
        stage('Package') {
            when { tag "v*" }
            steps {
                dir('installer') {
                    script {
                        def images = ['jmeter-master:${JMETER_TAG}',
                                    'kafka:2',
                                    'zookeeper:3',
                                    'mysql:5.7.25',
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
                        echo ${RELEASE}-b$BUILD_NUMBER > ./metersphere/version
                        #保存镜像
                        rm -rf images && mkdir images && cd images
                        docker save ${IMAGE_PREFIX}/metersphere:${RELEASE} -o metersphere.tar
                        docker save ${IMAGE_PREFIX}/ms-node-controller:${RELEASE} -o ms-node-controller.tar
                        docker save ${IMAGE_PREFIX}/ms-data-streaming:${RELEASE} -o ms-data-streaming.tar
                        docker save ${IMAGE_PREFIX}/jmeter-master:${JMETER_TAG} -o jmeter-master.tar
                        docker save ${IMAGE_PREFIX}/kafka:2 -o kafka.tar
                        docker save ${IMAGE_PREFIX}/zookeeper:3 -o zookeeper.tar
                        docker save ${IMAGE_PREFIX}/mysql:5.7.25 -o mysql.tar
                        cd ..

                        #修改安装参数
                        sed -i -e "s#MS_TAG=.*#MS_TAG=${RELEASE}#g" install.conf
                        sed -i -e "s#MS_PREFIX=.*#MS_PREFIX=${IMAGE_PREFIX}#g" install.conf
                        sed -i -e "s#MS_JMETER_TAG=.*#MS_JMETER_TAG=${JMETER_TAG}#g" install.conf

                        #获取docker
                        rm -rf docker*
                        wget http://fit2cloud2-offline-installer.oss-cn-beijing.aliyuncs.com/tools/docker.zip
                        unzip docker.zip
                        rm -rf __MACOSX
                        rm -rf docker.zip

                        rm -rf metersphere-release*.tar.gz

                        #打包离线包
                        touch metersphere-release-${RELEASE}-offline.tar.gz
                        tar czvf metersphere-release-${RELEASE}-offline.tar.gz . --transform "s/^\\./metersphere-release-${RELEASE}-offline/" \\
                            --exclude metersphere-release-${RELEASE}-offline.tar.gz \\
                            --exclude .git

                        #打包在线包
                        touch metersphere-release-${RELEASE}.tar.gz
                        tar czvf metersphere-release-${RELEASE}.tar.gz . --transform "s/^\\./metersphere-release-${RELEASE}/" \\
                            --exclude metersphere-release-${RELEASE}.tar.gz \\
                            --exclude metersphere-release-${RELEASE}-offline.tar.gz \\
                            --exclude .git \\
                            --exclude images \\
                            --exclude docker

                        md5sum -b metersphere-release-${RELEASE}-offline.tar.gz | awk '{print $1}' > metersphere-release-${RELEASE}-offline.tar.gz.md5
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
                                curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-release-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-release-${RELEASE}.tar.gz
                            '''
                        }
                    }
                }
            }
        }
        stage('Archive') {
            when { tag "v*" }
            steps {
                archiveArtifacts artifacts: 'installer/*.tar.gz,installer/quick_start.sh,installer/*.md5', followSymlinks: false
            }
        }
        stage('Upload') {
            when { tag pattern: "^v\\d+\\.\\d+\\.\\d+\$", comparator: "REGEXP"}
            steps {
                dir('installer') {
                    echo "UPLOADING"
                    withCredentials([usernamePassword(credentialsId: 'OSSKEY', passwordVariable: 'SK', usernameVariable: 'AK')]) {
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-release-${RELEASE}-offline.tar.gz ./metersphere-release-${RELEASE}-offline.tar.gz")
                        sh("java -jar /opt/uploadToOss.jar $AK $SK fit2cloud2-offline-installer metersphere/release/metersphere-release-${RELEASE}-offline.tar.gz.md5 ./metersphere-release-${RELEASE}-offline.tar.gz.md5")
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