#!/bin/bash
# Integration test for glance service
# Test runs mysql,memcached,keystone and glance container and checks whether glance is running on public and admin ports

DOCKER_PROJ_NAME=${DOCKER_PROJ_NAME:-''}
CONT_PREFIX=test

. lib/functions.sh

http_proxy_args="-e http_proxy=${http_proxy:-} -e https_proxy=${https_proxy:-} -e no_proxy=${no_proxy:-}"

cleanup() {
    echo "Clean up ..."
    docker stop ${CONT_PREFIX}_mariadb
    docker stop ${CONT_PREFIX}_rabbitmq
    docker stop ${CONT_PREFIX}_memcached
    docker stop ${CONT_PREFIX}_keystone
    docker stop ${CONT_PREFIX}_cinder
    docker stop ${CONT_PREFIX}_nfs

    docker rm -v ${CONT_PREFIX}_mariadb
    docker rm -v ${CONT_PREFIX}_rabbitmq
    docker rm -v ${CONT_PREFIX}_memcached
    docker rm -v ${CONT_PREFIX}_keystone
    docker rm -v ${CONT_PREFIX}_cinder
    docker rm -v ${CONT_PREFIX}_nfs

    rm -rf /tmp/cindertest
}

cleanup

##### Start Containers

mkdir -p /tmp/cindertest
echo "Starting nfs container ..."
docker run  --net=host -d --privileged --name ${CONT_PREFIX}_nfs \
       -v /tmp/cindertest:/cindervols -e SHARED_DIRECTORY=/cindervols \
       itsthenetwork/nfs-server-alpine:latest

echo "Wait till nfs server is running ."
wait_for_port 2049 120

echo "Starting mariadb container ..."
docker run  --net=host -d -e MYSQL_ROOT_PASSWORD=veryS3cr3t --name ${CONT_PREFIX}_mariadb \
       mariadb:10.1

echo "Wait till mariadb is running ."
wait_for_port 3306 120

echo "Starting RabbitMQ container ..."
docker run -d --net=host -e DEBUG= --name ${CONT_PREFIX}_rabbitmq rabbitmq

echo "Wait till Rabbitmq is running ."
wait_for_port 5672 120

# create openstack user in rabbitmq
docker exec ${CONT_PREFIX}_rabbitmq rabbitmqctl add_user openstack veryS3cr3t
docker exec ${CONT_PREFIX}_rabbitmq rabbitmqctl set_permissions openstack '.*' '.*' '.*'

echo "Starting Memcached node (tokens caching) ..."
docker run -d --net=host -e DEBUG= --name ${CONT_PREFIX}_memcached memcached

echo "Wait till Memcached is running ."
wait_for_port 11211 30

# build cinder container from current sources
./build.sh

# create databases
create_db_osadmin keystone keystone veryS3cr3t veryS3cr3t
create_db_osadmin cinder cinder veryS3cr3t veryS3cr3t

echo "Starting keystone container"
docker run -d --net=host \
           -e DEBUG="true" \
           -e DB_SYNC="true" \
           $http_proxy_args \
           --name ${CONT_PREFIX}_keystone ${DOCKER_PROJ_NAME}keystone:latest

echo "Wait till keystone is running ."

wait_for_port 5000 120
ret=$?
if [ $ret -ne 0 ]; then
    echo "Error: Port 5000 (Keystone) not bounded!"
    exit $ret
fi

echo "Starting cinder container"
docker run -d --net=host --privileged \
           -e DEBUG="true" \
           -e DB_SYNC="true" \
           $http_proxy_args \
           --name ${CONT_PREFIX}_cinder ${DOCKER_PROJ_NAME}cinder:latest

echo "Return code $?"

# bootstrap openstack settings and upload image to glance
set +e
docker run --net=host --rm $http_proxy_args ${DOCKER_PROJ_NAME}osadmin /bin/bash -c ". /app/tokenrc; bash /app/bootstrap.sh"
ret=$?
if [ $ret -ne 0 ] && [ $ret -ne 128 ]; then
    echo "Error: Keystone bootstrap error ${ret}!"
    exit $ret
fi
set -e


# Test whether we can create test volume
docker run --net=host --rm $http_proxy_args ${DOCKER_PROJ_NAME}osadmin /bin/bash -c ". /app/adminrc; openstack volume create --size 1 testvol"
ret=$?
if [ $ret -ne 0 ]; then
    echo "Error: Volume test creation error ${ret}!"
    exit $ret
fi

echo "======== Success :) ========="

if [[ "$1" != "noclean" ]]; then
    cleanup
fi
