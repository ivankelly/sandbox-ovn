FROM debian:stable
MAINTAINER dev@midokura.com
	   
ADD sources.list /etc/apt/sources.list
RUN apt-get -qy update && apt-get -qy build-dep openvswitch \
    && apt-get install -qy git emacs-nox vim tcpdump
RUN git clone https://github.com/openvswitch/ovs.git 
WORKDIR ovs
RUN git checkout v2.5.0
RUN autoreconf -fi && ./configure --prefix=/usr && make clean install

WORKDIR /