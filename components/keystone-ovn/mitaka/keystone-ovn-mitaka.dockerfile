FROM ubuntu-upstart:14.04
MAINTAINER MidoNet (http://midonet.org)

ADD conf/cloudarchive-ost.list /etc/apt/sources.list.d/cloudarchive-ost.list
RUN apt-get install -qy ubuntu-cloud-keyring
RUN apt-get -q update && apt-get -qy dist-upgrade
RUN echo "manual" > /etc/init/keystone.override
RUN apt-get install -qy --no-install-recommends keystone python-openstackclient
RUN sed -i 's/#debug = false/debug = true/' /etc/keystone/keystone.conf

EXPOSE 5000 35357

ADD bin/run-keystone.sh /run-keystone.sh
ADD conf/keystonerc /keystonerc

CMD ["/run-keystone.sh"]

