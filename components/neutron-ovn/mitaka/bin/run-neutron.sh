#!/bin/bash -x

# Prepare neutron database before starting
mysqladmin -w120 --connect-timeout 1 -h mariadb -uroot -proot -f drop neutron
mysqladmin -w120 --connect-timeout 1 -h mariadb -uroot -proot -f create neutron

# Setup keystone
OS_SERVICE_TOKEN="ADMIN"
OS_SERVICE_ENDPOINT="http://keystone:35357/v2.0"
KEYSTONE="keystone --os-endpoint=$OS_SERVICE_ENDPOINT --os-token=$OS_SERVICE_TOKEN --os-auth-url=$OS_SERVICE_ENDPOINT"

# Wait for keystone to be available
MAX_WAIT=30
$KEYSTONE discover 2> /dev/null | grep 'Keystone found at'
while [ $? = 1 -a $MAX_WAIT -gt 0 ]; do
    sleep 1
    MAX_WAIT=$((MAX_WAIT - 1))
    $KEYSTONE discover 2> /dev/null | grep 'Keystone found at'
done
$KEYSTONE discover 2> /dev/null | grep 'Keystone found at'
if [ $? = 1 ]; then
    echo "ERROR Keystone taking too long to start"
    exit
fi

# Create users and endpoints
$KEYSTONE tenant-create --name service --description "Service tenant"
$KEYSTONE user-create --name neutron --pass neutron
$KEYSTONE user-role-add --user neutron --tenant service --role admin
$KEYSTONE user-role-add --user neutron --tenant service --role __member__
$KEYSTONE service-create --name neutron --type network --description "OSt network"
NEUTRON_SERVICE_ID=$($KEYSTONE service-list | awk  '/ network / {print $2}' | xargs | cut -d' ' -f1)
echo $NEUTRON_SERVICE_ID

NEUTRON_IP=$(ip a show dev eth0 | awk '/inet / { gsub("/.*", "", $2); print $2 }')
$KEYSTONE endpoint-create   --service-id $NEUTRON_SERVICE_ID \
          --publicurl http://$NEUTRON_IP:9696 \
          --internalurl http://$NEUTRON_IP:9696 \
          --adminurl http://$NEUTRON_IP:9696 \
          --region regionOne

NORTHBOUNDDB_IP=$(cat /etc/hosts | awk '/northbounddb/ { print $1 ; exit } ')
sed -i "s/REPLACE_NORTHBOUNDDB/$NORTHBOUNDDB_IP/" /etc/neutron/neutron.conf

neutron-db-manage --config-file /etc/neutron/neutron.conf upgrade head

exec /sbin/init
