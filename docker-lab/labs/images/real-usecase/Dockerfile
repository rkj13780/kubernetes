FROM armdocker.rnd.ericsson.se/rhel7:7.6
RUN useradd toscao
COPY toscao.tar.gz /tmp/
RUN tar -zxf /tmp/toscao.tar.gz -C /
COPY resolv.conf /etc/
RUN yum install -y httpd mod_wsgi mod_ssl mod_nss bind-utils
RUN ln -s /opt/toscao/lib/aria/pip/__main__.py /usr/bin/pip
RUN ln -s /opt/toscao/src/apache-aria/aria/orchestrator/execution_plugin/ctx_proxy/client.py /usr/bin/ctx
COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY toscao.conf /etc/httpd/conf.d/toscao.conf
#COPY 00-base.conf 00-dav.conf 00-proxy.conf /etc/httpd/conf.modules.d/
RUN mkdir -p /var/lib/toscao/.aria/hooks/csarhooks
RUN chown -R toscao:toscao /opt/toscao /usr/share/toscao/conf /var/log/toscao /var/www/toscao /var/lib/toscao
USER toscao
ENV ARIA_WORKDIR /var/lib/toscao
USER root
ENV PYTHONPATH=/opt/toscao/src/apache-aria:/opt/toscao/src/apache-aria/extensions:/opt/toscao/src:/opt/toscao/lib/aria:/opt/toscao/lib/tosca_o \
    TOSCAO_HOME=/usr/share/toscao \
    TOSCAO_LOG_LEVEL=INFO
#RUN /usr/bin/pip install psycopg2-binary
RUN /usr/bin/pip install 'psycopg2-binary==2.7.4' -i https://arm.rnd.ki.sw.ericsson.se/artifactory/api/pypi/pypi-remote/simple
RUN ln -sf /dev/stdout /var/log/httpd/toscao_log
EXPOSE 7001
ENTRYPOINT /usr/sbin/httpd -DFOREGROUND

