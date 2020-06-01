support_config='''
MS_BASE
MS_TAG
MS_PREFIX
MS_MODE
MS_PORT
MS_EXTERNAL_MYSQL
MS_MYSQL_HOST
MS_MYSQL_PORT
MS_MYSQL_DB
MS_MYSQL_USER
MS_MYSQL_PASSWORD
MS_EXTERNAL_KAFKA
MS_KAFKA_TOPIC
MS_KAFKA_HOST
MS_KAFKA_PORT
MS_KAFKA_LOG_TOPIC
'''

install_config() {
    val=$((grep -E "^$1=" install.conf 2>/dev/null || echo "$1=__DEFAULT__") | head -n 1 | cut -d '=' -f 2-)

    if [[ $val == __DEFAULT__ ]]
    then
        case $1 in
            MS_BASE)
                echo -n "/opt"
                ;;
            MS_TAG)
                echo -n "release"
                ;;
            MS_PREFIX)
                echo -n "metersphere"
                ;;
            MS_MODE)
                echo -n "allinone"
                ;;
            MS_PORT)
                echo -n "8081"
                ;;
            MS_EXTERNAL_MYSQL)
                echo -n "false"
                ;;
            MS_MYSQL_HOST)
                echo -n "mysql"
                ;;
            MS_MYSQL_PORT)
                echo -n "3306"
                ;;
            MS_MYSQL_DB)
                echo -n "metersphere"
                ;;
            MS_MYSQL_USER)
                echo -n "root"
                ;;
            MS_MYSQL_PASSWORD)
                echo -n "Password123@mysql"
                ;;
            MS_EXTERNAL_KAFKA)
                echo -n "false"
                ;;
            MS_KAFKA_TOPIC)
                echo -n "JMETER_METRICS"
                ;;
            MS_KAFKA_HOST)
                echo -n $(hostname -I|cut -d" " -f 1)
                ;;
            MS_KAFKA_PORT)
                echo -n "19092"
                ;;
            MS_KAFKA_LOG_TOPIC)
                echo -n "JMETER_LOGS"
                ;;
        esac
    else
        echo -n $val
    fi
}