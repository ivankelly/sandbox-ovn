FROM sandbox/openvswitch:2.5.0

RUN apt-get install -qy supervisor uuid-runtime
ADD bin/run-hypervisor /run-hypervisor
ADD bin/create_veth_pair /usr/bin/create_veth_pair
ADD conf/supervisord.conf /supervisord.conf
ADD conf/root_bashrc /root/.bashrc

CMD /run-hypervisor