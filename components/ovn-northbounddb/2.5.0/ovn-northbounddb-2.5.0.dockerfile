FROM sandbox/openvswitch:2.5.0

WORKDIR /
RUN echo "export OVN_NB_DB=tcp:127.0.0.1:1234" >> /root/.bashrc
RUN ovsdb-tool create ovnnb.db /usr/share/openvswitch/ovn-nb.ovsschema
CMD ovsdb-server --remote=ptcp:1234 ovnnb.db