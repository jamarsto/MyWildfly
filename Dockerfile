FROM jboss/wildfly:latest
USER root
RUN yum -y update && yum -y install httpd && yum -y install rsync && yum clean all
ADD customisation /opt/jboss/wildfly/customisation
RUN rm -rf /opt/jboss/wildfly/standalone/deployments/* && rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history && echo "Proxypass / http://localhost:8080/" >> /etc/httpd/conf/httpd.conf && echo "ProxypassReverse / http://localhost:8080/" >> /etc/httpd/conf/httpd.conf
CMD /opt/jboss/wildfly/customisation/startup.sh
