FROM jboss/wildfly:latest
USER root
RUN yum -y update && yum -y install httpd && yum -y install rsync && yum clean all
ADD httpd.conf /etc/httpd/conf/httpd.conf
ADD customisation /opt/jboss/wildfly/customisation
RUN rm -rf /opt/jboss/wildfly/standalone/deployments/* && rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history
CMD /opt/jboss/wildfly/customisation/startup.sh
