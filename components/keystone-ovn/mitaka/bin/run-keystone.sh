#!/usr/bin/env bash

set -x

keystone-manage db_sync

python /usr/bin/keystone-all --config-file=/etc/keystone/keystone.conf --log-file=/var/log/keystone/keystone.log &

OS_SERVICE_TOKEN="ADMIN"
OS_SERVICE_ENDPOINT="http://localhost:35357/v2.0"

KEYSTONE="keystone --os-endpoint=$OS_SERVICE_ENDPOINT --os-token=$OS_SERVICE_TOKEN"

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

# Create roles users and endpoints
$KEYSTONE role-create --name admin
$KEYSTONE role-create --name __member__

$KEYSTONE tenant-create --name admin --description "Admin tenant"
$KEYSTONE user-create --name admin --pass admin
$KEYSTONE user-role-add --user admin --tenant admin --role admin
$KEYSTONE user-role-add --user admin --tenant admin --role __member__

$KEYSTONE service-create --name keystone --type identity --description "OSt identity"

KEYSTONE_SERVICE_ID=$($KEYSTONE service-list | awk  '/ identity / {print $2}' | xargs | cut -d' ' -f1)
KEYSTONE_IP=$(ip a show dev eth0 | awk '/inet / { gsub("/.*", "", $2); print $2 }')

$KEYSTONE endpoint-create \
  --service-id $KEYSTONE_SERVICE_ID \
  --publicurl http://$KEYSTONE_IP:5000/v2.0 \
  --internalurl http://$KEYSTONE_IP:5000/v2.0 \
  --adminurl http://$KEYSTONE_IP:35357/v2.0 \
  --region regionOne

# Wait until keystone-all process exits
wait

