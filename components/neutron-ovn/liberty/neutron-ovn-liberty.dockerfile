FROM ubuntu-upstart:14.04
MAINTAINER MidoNet (http://midonet.org)

ADD conf/keystonerc /keystonerc

ADD bin/run-neutron.sh /run-neutron.sh

RUN apt-get -qy update && apt-get install -qy ubuntu-cloud-keyring

ADD conf/cloudarchive-ost.list /etc/apt/sources.list.d/cloudarchive-ost.list
RUN apt-get -qy update && apt-get install -qy --no-install-recommends \
    ubuntu-cloud-keyring curl \
    neutron-server \
    python-neutronclient \
    python-keystoneclient \
    python-mysql.connector \
    python-openssl \
    mariadb-client

CMD ["bash"]
