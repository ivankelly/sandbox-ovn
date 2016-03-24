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

# Sending traffic

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

# TODO

* Set up neutron image, so that we don't have to use nbctl directly.
