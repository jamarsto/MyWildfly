FROM jboss/wildfly:latest
USER root
RUN yum -y update && yum -y install httpd && yum -y install rsync && yum -y install openssh-server && echo "root:Docker!" | chpasswd && yum clean all && /usr/bin/ssh-keygen -A && rm -rf /opt/jboss/wildfly/standalone/deployments/* && rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history && echo "Proxypass / http://localhost:8080/" >> /etc/httpd/conf/httpd.conf && echo "ProxypassReverse / http://localhost:8080/" >> /etc/httpd/conf/httpd.conf
RUN mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chown -R root:root ~/.ssh && chmod -R 700 ~/.ssh 
COPY sshd_config /etc/ssh/
RUN chown -R root:root /etc/ssh/sshd_config
ADD customisation /opt/jboss/wildfly/customisation
EXPOSE 2222 80
CMD /opt/jboss/wildfly/customisation/startup.sh
