FROM sandbox/openvswitch:2.5.0

ADD bin/run-northd /run-northd
CMD /run-northd
