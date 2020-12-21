pipeline {
    agent {
        node {
            label 'metersphere'
        }
    }
    options { 
        quietPeriod(600)
        checkoutToSubdirectory('installer')
    }
    parameters { 
        string(name: 'IMAGE_FREFIX', defaultValue: 'registry.cn-qingdao.aliyuncs.com/metersphere', description: '构建后的 Docker 镜像带仓库名的前缀')
    }
    stages {
        stage('Preparation') {
            steps {
                script {
                    def BRANCH = 'v1.6'
                    def RELEASE = 'v1.6.0'
                }
                // Get some code from a GitHub repository
                dir('ms-server') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/metersphere.git', branch: '${BRANCH}'
                }
                dir('ms-node-controller') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/node-controller.git', branch: '${BRANCH}'
                }
                dir('ms-data-streaming') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/data-streaming.git', branch: '${BRANCH}'
                }
                dir('jenkins-plugin') {
                    git credentialsId:'metersphere-registry', url: 'git@github.com:metersphere/jenkins-plugin.git', branch: '${BRANCH}'
                }
            }
        }

        stage('Tag Other Repos') {
            steps {
                dir('ms-server') {
                   sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                   sh("git push -f origin --tags")
                }
                dir('ms-node-controller') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin --tags")
                }
                dir('ms-data-streaming') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin --tags")
                }
                dir('jenkins-plugin') {
                    sh("git tag -f -a ${RELEASE} -m 'Tagged by Jenkins'")
                    sh("git push -f origin --tags")
                }
            }
        }   

        stage('Package') {
            steps {
                dir('installer') {
                    script {
                        def images = ['jmeter-master:5.3-ms14',
                                    'kafka:2',
                                    'zookeeper:3',
                                    'mysql:5.7.25',
                                    'metersphere:${RELEASE}',
                                    'ms-node-controller:${RELEASE}',
                                    'ms-data-streaming:${RELEASE}']
                        for (image in images) {
                            waitUntil {
                                def r = sh script: 'docker pull ${image}', returnStdout: true
                                r == 0;
                            }
                        }
                    }
                    sh '''
                        echo ${RELEASE}-b$BUILD_NUMBER > ./metersphere/version
                        #保存镜像
                        mkdir images && cd images
                        docker save ${IMAGE_FREFIX}/metersphere:${RELEASE} -o metersphere.tar
                        docker save ${IMAGE_FREFIX}/ms-node-controller:${RELEASE} -o ms-node-controller.tar
                        docker save ${IMAGE_FREFIX}/ms-data-streaming:${RELEASE} -o ms-data-streaming.tar
                        docker save ${IMAGE_FREFIX}/jmeter-master:5.3-ms14 -o jmeter-master.tar
                        docker save ${IMAGE_FREFIX}/kafka:2 -o kafka.tar
                        docker save ${IMAGE_FREFIX}/zookeeper:3 -o zookeeper.tar
                        docker save ${IMAGE_FREFIX}/mysql:5.7.25 -o mysql.tar
                        cd ..

                        #修改安装参数
                        sed -i -e "s#MS_TAG=.*#MS_TAG=${RELEASE}#g" install.conf
                        sed -i -e "s#MS_PREFIX=.*#MS_PREFIX=${IMAGE_FREFIX}#g" install.conf
                        sed -i -e "s#MS_JMETER_TAG=.*#MS_JMETER_TAG=5.3-ms14#g" install.conf

                        #获取docker
                        wget http://fit2cloud2-offline-installer.oss-cn-beijing.aliyuncs.com/tools/docker.zip
                        unzip docker.zip
                        rm -rf docker.zip
                        rm -rf __MACOSX

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
                    '''
                }
            }
        }

        stage('Release') {
            steps {
                withCredentials([string(credentialsId: 'gitrelease', variable: 'TOKEN')]) {
                    withEnv(["TOKEN=$TOKEN", "branch=$BRANCH", "RELEASE=$RELEASE"]) {
                        sh script: '''
                            release=$(curl -XPOST -H "Authorization:token $TOKEN" --data "{\\"tag_name\\": \\"${RELEASE}\\", \\"target_commitish\\": \\"${branch}\\", \\"name\\": \\"${RELEASE}\\", \\"body\\": \\"\\", \\"draft\\": false, \\"prerelease\\": true}" https://api.github.com/repos/metersphere/metersphere/releases)
                            id=$(echo "$release" | sed -n -e \'s/"id":\\ \\([0-9]\\+\\),/\\1/p\' | head -n 1 | sed \'s/[[:blank:]]//g\')
                            curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @quick_start.sh https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=quick_start.sh
                            curl -XPOST -H "Authorization:token $TOKEN" -H "Content-Type:application/octet-stream" --data-binary @metersphere-release-${RELEASE}.tar.gz https://uploads.github.com/repos/metersphere/metersphere/releases/${id}/assets?name=metersphere-release-${RELEASE}.tar.gz
                        '''
                    }
                }
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'installer/*.tar.gz,installer/quick_start.sh,installer/*.md5', followSymlinks: false
            }
        }
    }
    post('Notification') {
        always {
            sh "echo \$WEBHOOK\n"
            withCredentials([string(credentialsId: 'wechat-bot-webhook', variable: 'WEBHOOK')]) {
                qyWechatNotification failSend: true, mentionedId: '', mentionedMobile: '', webhookUrl: "$WEBHOOK"
            }
        }
    }
}