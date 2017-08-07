#!/bin/bash
set -e

# set debug
DEBUG_OPT=false
if [[ $DEBUG ]]; then
        set -x
        DEBUG_OPT=true
fi

# if cinder is not installed, quit
which cinder-manage &>/dev/null || exit 1

# define variable defaults

DB_HOST=${DB_HOST:-127.0.0.1}
DB_PORT=${DB_PORT:-3306}
DB_PASSWORD=${DB_PASSWORD:-veryS3cr3t}

MY_IP=${MY_IP:-127.0.0.1}
BIND_HOST=${BIND_HOST:-0.0.0.0}
GLANCE_HOST=${GLANCE_HOST:-127.0.0.1}
GLANCE_API_SERVERS=${GLANCE_API_SERVERS:-"http:\/\/127.0.0.1:9292"}
GLANCE_API_VERSION=${GLANCE_API_VERSION:-2}
HOSTNAME=$(hostname -f)
RABBITMQ_HOST=${RABBITMQ_HOST:-127.0.0.1}
RABBITMQ_PORT=${RABBITMQ_PORT:-5672}
RABBITMQ_USER=${RABBITMQ_USER:-openstack}
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-veryS3cr3t}
SERVICE_TENANT_NAME=${ADMIN_TENANT_NAME:-service}
SERVICE_USER=${ADMIN_USER:-cinder}
SERVICE_PASSWORD=${ADMIN_PASSWORD:-veryS3cr3t}
MEMCACHED_SERVERS=${MEMCACHED_SERVERS:-'127.0.0.1:11211'}
KEYSTONE_HOST=${KEYSTONE_HOST:-'127.0.0.1'}

NAS_HOST=${NAS_HOST:-127.0.0.1}
NAS_SHARE_PATH=${NAS_SHARE_PATH:-'\/'}
NAS_MOUNT_OPTIONS=${NAS_MOUNT_OPTIONS:-''}

INSECURE=${INSECURE:-true}

LOG_MESSAGE="Docker start script:"
OVERRIDE=0
CONF_DIR="/etc/cinder"
OVERRIDE_DIR="/cinder-override"
CONF_FILES=(`cd $CONF_DIR; find . -maxdepth 1 -type f`)
OVERRIDE_CONF_FILES=(`cd $OVERRIDE_DIR; find . -maxdepth 1 -type f`)

# check if external configs are provided
echo "$LOG_MESSAGE Checking if external config is provided.."
if [[ "$(ls -A $OVERRIDE_DIR)" ]]; then
        echo "$LOG_MESSAGE  ==> external configs found!. Using it."
        OVERRIDE=1
        for CONF in ${OVERRIDE_CONF_FILES[*]}; do
                rm -f "$CONF_DIR/$CONF"
                ln -s "$OVERRIDE_DIR/$CONF" "$CONF_DIR/$CONF"
        done
fi

if [[ $OVERRIDE -eq 0 ]]; then
        for CONF in ${CONF_FILES[*]}; do
                echo "$LOG_MESSAGE generating $CONF file ..."
                sed -i "s/_MY_IP_/$MY_IP/" $CONF_DIR/$CONF
                sed -i "s/_HOSTNAME_/$HOSTNAME/" $CONF_DIR/$CONF
		sed -i "s/_BIND_HOST_/$BIND_HOST/" $CONF_DIR/$CONF
                sed -i "s/\b_GLANCE_HOST_\b/$GLANCE_HOST/" $CONF_DIR/$CONF
                sed -i "s/\b_GLANCE_API_SERVERS_\b/$GLANCE_API_SERVERS/" $CONF_DIR/$CONF
                sed -i "s/\b_GLANCE_API_VERSION_\b/$GLANCE_API_VERSION/" $CONF_DIR/$CONF
                sed -i "s/\b_RABBITMQ_HOST_\b/$RABBITMQ_HOST/" $CONF_DIR/$CONF
                sed -i "s/\b_RABBITMQ_PORT_\b/$RABBITMQ_PORT/" $CONF_DIR/$CONF
                sed -i "s/\b_RABBITMQ_USER_\b/$RABBITMQ_USER/" $CONF_DIR/$CONF
                sed -i "s/\b_RABBITMQ_PASSWORD_\b/$RABBITMQ_PASSWORD/" $CONF_DIR/$CONF
                sed -i "s/_DB_HOST_/$DB_HOST/" $CONF_DIR/$CONF
                sed -i "s/_DB_PORT_/$DB_PORT/" $CONF_DIR/$CONF
                sed -i "s/_DB_PASSWORD_/$DB_PASSWORD/" $CONF_DIR/$CONF
                sed -i "s/_BIND_HOST_/$BIND_HOST/" $CONF_DIR/$CONF
                sed -i "s/_SERVICE_TENANT_NAME_/$SERVICE_TENANT_NAME/" $CONF_DIR/$CONF
                sed -i "s/_SERVICE_USER_/$SERVICE_USER/" $CONF_DIR/$CONF
                sed -i "s/_SERVICE_PASSWORD_/$SERVICE_PASSWORD/" $CONF_DIR/$CONF
                sed -i "s/_DEBUG_OPT_/$DEBUG_OPT/" $CONF_DIR/$CONF
                sed -i "s/_MEMCACHED_SERVERS_/$MEMCACHED_SERVERS/" $CONF_DIR/$CONF
                sed -i "s/_KEYSTONE_HOST_/$KEYSTONE_HOST/" $CONF_DIR/$CONF
                sed -i "s/_NAS_HOST_/$NAS_HOST/" $CONF_DIR/$CONF
                sed -i "s/_NAS_SHARE_PATH_/$NAS_SHARE_PATH/" $CONF_DIR/$CONF
                sed -i "s/_NAS_MOUNT_OPTIONS_/$NAS_MOUNT_OPTIONS/" $CONF_DIR/$CONF
                sed -i "s/_INSECURE_/$INSECURE/" $CONF_DIR/$CONF
        done
        echo "$LOG_MESSAGE  ==> done"
fi


[[ $DB_SYNC ]] && echo "Running db_sync ..." && cinder-manage db sync

echo "$LOG_MESSAGE starting cinder"
exec "$@"
