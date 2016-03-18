FROM sandbox/openvswitch:2.5.0

WORKDIR /
RUN ovsdb-tool create ovnsb.db /usr/share/openvswitch/ovn-sb.ovsschema
CMD ovsdb-server --remote=ptcp:1234 ovnsb.db