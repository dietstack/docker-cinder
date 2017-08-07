wait_for_port() {
    local port="$1"
    local timeout=$2
    local counter=0
    echo "Wait till app is bound to port $port "
    while [[ $counter -lt $timeout ]]; do
        local counter=$[counter + 1]
        if [[ ! `ss -ntl | grep ":${port}"` ]]; then
            echo -n ". "
        else
            echo ""
            break
        fi
        sleep 1
    done

    if [[ $timeout -eq $counter ]]; then
        exit 1
    fi
}

create_db_osadmin() {
    # Usage: create_db_osadmin keystone keystone veryS3cr3t veryS3cr3t
    local DB_NAME=$1
    local USER_NAME=$2
    local ROOT_DB_PASSWD=$3
    local SVC_DB_PASSWD=$4
    echo "Creating $DB_NAME database ..."
    MYSQL_CMD="docker run --rm --net=host osadmin mysql -h 127.0.0.1 -P 3306 -u root -p$ROOT_DB_PASSWD"
    $MYSQL_CMD -e "CREATE DATABASE $DB_NAME;"
    $MYSQL_CMD -e "CREATE USER '$USER_NAME'@'%' IDENTIFIED BY '$SVC_DB_PASSWD';"
    $MYSQL_CMD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$USER_NAME'@'%' WITH GRANT OPTION;"
}
