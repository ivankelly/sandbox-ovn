A bunch of docker images and compositions to play with OVN

# Setup

Install docker and sandbox if you don't have it already.

```
apt-get install python-pip python-dev git
curl https://get.docker.com/ | sudo sh
pip install git+https://github.com/midonet/midonet-sandbox.git
```

# Install the 2.5.0 kernel module

```
sudo dpkg -i ./packages/openvswitch-datapath-dkms_2.5.0-1_all.deb
sudo rmmod openvswitch # remove the dependencies until you can remove it
sudo modprobe vport_geneve
```

# Running the flavour

```
sandbox-manage -c sandbox-ovn.conf build-all ovn+multi 
sandbox-manage -c sandbox-ovn.conf run --name=test ovn+multi
```

NOTE: neutron may take a couple of minutes to start as it has to
initialize the database.

# Sending traffic (with neutron)

1. Create a network, subnet and 2 ports in neutron.
```
$ docker exec -it mnsandboxtest_neutron_1 bash
root@neutron:/# source /keystonerc
root@neutron /(keystone_admin)$ neutron
(neutron) net-create ovntest
Created a new network:
+-------------------------+--------------------------------------+
| Field                   | Value                                |
+-------------------------+--------------------------------------+
| admin_state_up          | True                                 |
| availability_zone_hints |                                      |
| availability_zones      |                                      |
| id                      | 221cf44c-7fcc-4022-bb44-7226cb32b835 |
| mtu                     | 0                                    |
| name                    | ovntest                              |
| port_security_enabled   | True                                 |
| router:external         | False                                |
| shared                  | False                                |
| status                  | ACTIVE                               |
| subnets                 |                                      |
| tenant_id               | e059d61e56f4496eb00c6cce1f6bd89c     |
+-------------------------+--------------------------------------+
(neutron) subnet-create ovntest 10.0.0.0/24
Created a new subnet:
+-------------------+--------------------------------------------+
| Field             | Value                                      |
+-------------------+--------------------------------------------+
| allocation_pools  | {"start": "10.0.0.2", "end": "10.0.0.254"} |
| cidr              | 10.0.0.0/24                                |
| dns_nameservers   |                                            |
| enable_dhcp       | True                                       |
| gateway_ip        | 10.0.0.1                                   |
| host_routes       |                                            |
| id                | f9e4b69f-1157-4241-97d5-2383ac62c2bf       |
| ip_version        | 4                                          |
| ipv6_address_mode |                                            |
| ipv6_ra_mode      |                                            |
| name              |                                            |
| network_id        | 221cf44c-7fcc-4022-bb44-7226cb32b835       |
| subnetpool_id     |                                            |
| tenant_id         | e059d61e56f4496eb00c6cce1f6bd89c           |
+-------------------+--------------------------------------------+
(neutron) port-create ovntest
Created a new port:
+-----------------------+---------------------------------------------------------------------------------+
| Field                 | Value                                                                           |
+-----------------------+---------------------------------------------------------------------------------+
| admin_state_up        | True                                                                            |
| allowed_address_pairs |                                                                                 |
| binding:host_id       |                                                                                 |
| binding:vif_details   | {"port_filter": true}                                                           |
| binding:vif_type      | ovs                                                                             |
| binding:vnic_type     | normal                                                                          |
| device_id             |                                                                                 |
| device_owner          |                                                                                 |
| extra_dhcp_opts       |                                                                                 |
| fixed_ips             | {"subnet_id": "f9e4b69f-1157-4241-97d5-2383ac62c2bf", "ip_address": "10.0.0.2"} |
| id                    | ebbe03a7-9b8e-459a-b51f-7d57a3cdddce                                            |
| mac_address           | fa:16:3e:50:58:ef                                                               |
| name                  |                                                                                 |
| network_id            | 221cf44c-7fcc-4022-bb44-7226cb32b835                                            |
| port_security_enabled | True                                                                            |
| security_groups       | daff3fd9-07ae-49c5-b8cd-f59626f48c52                                            |
| status                | DOWN                                                                            |
| tenant_id             | e059d61e56f4496eb00c6cce1f6bd89c                                                |
+-----------------------+---------------------------------------------------------------------------------+
(neutron) port-create ovntest
Created a new port:
+-----------------------+---------------------------------------------------------------------------------+
| Field                 | Value                                                                           |
+-----------------------+---------------------------------------------------------------------------------+
| admin_state_up        | True                                                                            |
| allowed_address_pairs |                                                                                 |
| binding:host_id       |                                                                                 |
| binding:vif_details   | {"port_filter": true}                                                           |
| binding:vif_type      | ovs                                                                             |
| binding:vnic_type     | normal                                                                          |
| device_id             |                                                                                 |
| device_owner          |                                                                                 |
| extra_dhcp_opts       |                                                                                 |
| fixed_ips             | {"subnet_id": "f9e4b69f-1157-4241-97d5-2383ac62c2bf", "ip_address": "10.0.0.3"} |
| id                    | 0be46601-5f5f-424a-a7f4-01751ae1737b                                            |
| mac_address           | fa:16:3e:31:f1:9d                                                               |
| name                  |                                                                                 |
| network_id            | 221cf44c-7fcc-4022-bb44-7226cb32b835                                            |
| port_security_enabled | True                                                                            |
| security_groups       | daff3fd9-07ae-49c5-b8cd-f59626f48c52                                            |
| status                | DOWN                                                                            |
| tenant_id             | e059d61e56f4496eb00c6cce1f6bd89c                                                |
+-----------------------+---------------------------------------------------------------------------------+
```

2. Create a port and bind it on hypervisor1, taking the MAC, IP and
   iface-id from Neutron.
```
$ docker exec -it mnsandboxtest_hypervisor1_1 bash
root@hypervisor1:/# create_veth_pair -n port1 -i 10.0.0.2/24 -m fa:16:3e:50:58:ef
root@hypervisor1:/# ovs-vsctl --db=unix:/ovsdb-local.sock add-port br-int port1dp -- set Interface port1dp external_ids:iface-id=ebbe03a7-9b8e-459a-b51f-7d57a3cdddce
```

3. Create a port and bind it on hypervisor2.
```
$ docker exec -it mnsandboxtest_hypervisor2_1 bash
root@hypervisor2:/# create_veth_pair -n port2 -i 10.0.0.3/24 -m fa:16:3e:31:f1:9d
root@hypervisor2:/# ovs-vsctl --db=unix:/ovsdb-local.sock add-port br-int port2dp -- set Interface port2dp external_ids:iface-id=0be46601-5f5f-424a-a7f4-01751ae1737b
```

4. Ping between the ports.
```
root@hypervisor2:/# ip netns exec port2 ping 10.0.0.3
PING 10.0.0.3 (10.0.0.3): 56 data bytes
64 bytes from 10.0.0.3: icmp_seq=0 ttl=64 time=0.122 ms
64 bytes from 10.0.0.3: icmp_seq=1 ttl=64 time=0.046 ms
^C--- 10.0.0.3 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.046/0.084/0.122/0.038 ms
```

# Sending traffic (without neutron)

1. Create a simple topology in the northbound database.
```
$ docker exec -it mnsandboxtest_northbounddb_1 bash
root@northbounddb:/# ovn-nbctl lswitch-add sw0
root@northbounddb:/# ovn-nbctl lport-add sw0 sw0-port1
root@northbounddb:/# ovn-nbctl lport-add sw0 sw0-port2
root@northbounddb:/# ovn-nbctl lport-set-addresses sw0-port1 00:00:00:00:00:01
root@northbounddb:/# ovn-nbctl lport-set-addresses sw0-port2 00:00:00:00:00:02
root@northbounddb:/# ovn-nbctl lport-set-port-security sw0-port1 00:00:00:00:00:01
root@northbounddb:/# ovn-nbctl lport-set-port-security sw0-port2 00:00:00:00:00:02
```

2. Create a port and bind it on hypervisor1.
```
$ docker exec -it mnsandboxtest_hypervisor1_1 bash
root@hypervisor1:/# create_veth_pair -n port1 -i 10.0.0.1/24 -m 00:00:00:00:00:01
root@hypervisor1:/# ovs-vsctl --db=unix:/ovsdb-local.sock add-port br-int port1dp -- set Interface port1dp external_ids:iface-id=sw0-port1
```

3. Create a port and bind it on hypervisor2.
```
$ docker exec -it mnsandboxtest_hypervisor2_1 bash
root@hypervisor2:/# create_veth_pair -n port2 -i 10.0.0.2/24 -m 00:00:00:00:00:02
root@hypervisor2:/# ovs-vsctl --db=unix:/ovsdb-local.sock add-port br-int port2dp -- set Interface port2dp external_ids:iface-id=sw0-port2
```

4. Ping between the ports.
```
root@hypervisor1:/# ip netns exec port1 ping 10.0.0.2
PING 10.0.0.2 (10.0.0.2): 56 data bytes
64 bytes from 10.0.0.2: icmp_seq=0 ttl=64 time=0.597 ms
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.052 ms
^C--- 10.0.0.2 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 0.052/0.325/0.597/0.273 ms
```

