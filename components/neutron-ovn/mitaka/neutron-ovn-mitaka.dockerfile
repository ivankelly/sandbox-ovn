FROM ubuntu-upstart:14.04
MAINTAINER MidoNet (http://midonet.org)

COPY conf/cloudarchive-ost.list /etc/apt/sources.list.d/cloudarchive-ost.list

RUN apt-get -q update
RUN apt-get install -qy ubuntu-cloud-keyring
RUN apt-get install -qy --no-install-recommends --force-yes \
                            curl git python-pip \
                            python-mysql.connector \
                            python-openssl \
                            mariadb-client \
                            neutron-server \
                            python-neutronclient \
                            python-keystoneclient

RUN pip install git+https://github.com/openstack/networking-ovn.git

COPY conf/keystonerc /keystonerc
COPY bin/run-neutron.sh /run-neutron.sh
COPY conf/neutron.conf /etc/neutron/neutron.conf

CMD ["/run-neutron.sh"]