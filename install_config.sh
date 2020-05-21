support_config='''
base_dir
metersphere_image_tag
metersphere_image_prefix
install_mode
metersphere_server_port
external_mysql
mysql_host
mysql_port
mysql_dbname
mysql_username
mysql_password
external_kafka
kafka_topic
kafka_host
kafka_port
kafka_log_topic
'''

install_config() {
    val=$((grep -E "^$1=" install.conf 2>/dev/null || echo "$1=__DEFAULT__") | head -n 1 | cut -d '=' -f 2-)

    if [[ $val == __DEFAULT__ ]]
    then
        case $1 in
            base_dir)
                echo -n "/opt"
                ;;
            metersphere_image_tag)
                echo -n "release"
                ;;
            metersphere_image_prefix)
                echo -n "metersphere"
                ;;
            install_mode)
                echo -n "allinone"
                ;;
            metersphere_server_port)
                echo -n "8081"
                ;;
            external_mysql)
                echo -n "false"
                ;;
            mysql_host)
                echo -n "mysql"
                ;;
            mysql_port)
                echo -n "3306"
                ;;
            mysql_dbname)
                echo -n "metersphere"
                ;;
            mysql_username)
                echo -n "root"
                ;;
            mysql_password)
                echo -n "Password123@mysql"
                ;;
            external_kafka)
                echo -n "false"
                ;;
            kafka_topic)
                echo -n "JMETER_METRICS"
                ;;
            kafka_host)
                echo -n $(hostname -I|cut -d" " -f 1)
                ;;
            kafka_port)
                echo -n "19092"
                ;;
            kafka_log_topic)
                echo -n "JMETER_LOGS"
                ;;
        esac
    else
        echo -n $val
    fi
}