FROM amazonlinux:2

# >>>>> !!!!!! Exporter part 
ARG REPO_FPM="hipages/php-fpm_exporter"
ARG PHP_FPM_EXPORTER_VERSION=v2.2.0
ARG REPO_APACHE="Lusitaniae/apache_exporter"
ARG APACHE_EXPORTER_VERSION=v1.0.11
# >>>>> !!!!!!

ENV LANG=en_US.utf-8
ENV LC_ALL=en_US.utf-8

RUN yum update -y && \
    amazon-linux-extras install -y epel && \
    amazon-linux-extras install -y php8.2 && \
    yum install -y -q -e 0 httpd php-fpm wget pip file curl jq tar gzip && \
    pip install supervisor && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    mkdir -p /var/log/supervisor 

# >>>>> !!!!!! Exporter part
RUN echo "---> 1. PHP-FPM Exporter" && \
      DOWNLOAD_URL_FPM=$(curl -s "https://api.github.com/repos/${REPO_FPM}/releases/tags/${PHP_FPM_EXPORTER_VERSION}" \
      | jq -r '.assets[] | select(.name | contains("linux_amd64.tar.gz")) | .browser_download_url') && \
      curl -sL -o fpm_exporter.tar.gz "${DOWNLOAD_URL_FPM}" && \
      tar -xvzf fpm_exporter.tar.gz php-fpm_exporter && \
      install php-fpm_exporter /usr/local/bin/ && \
      rm -f fpm_exporter.tar.gz php-fpm_exporter && \
    echo "---> 2. Apache Exporter" && \
      DOWNLOAD_URL_APACHE=$(curl -s "https://api.github.com/repos/${REPO_APACHE}/releases/tags/${APACHE_EXPORTER_VERSION}" \
      | jq -r '.assets[] | select(.name | contains("linux-amd64.tar.gz")) | .browser_download_url') && \
      curl -sL -o apache_exporter.tar.gz "${DOWNLOAD_URL_APACHE}" && \
      tar -xvzf apache_exporter.tar.gz --strip-components=1 */apache_exporter && \
      install apache_exporter /usr/local/bin/ && \
      rm -f apache_exporter.tar.gz apache_exporter && \
    echo "---> 3. Exporters Exec" && \
      chmod +x /usr/local/bin/php-fpm_exporter && \
      chmod +x /usr/local/bin/apache_exporter
# >>>>> !!!!!!

COPY config/vhost.conf /etc/httpd/conf.d/vhost.conf
COPY config/www.conf /etc/php-fpm.d/www.conf
COPY config/supervisord.conf /etc/supervisor/supervisord.conf

COPY index.php /var/www/html/index.php
RUN mkdir -p /var/run/php-fpm && chown apache:apache /var/run/php-fpm
RUN chown -R apache:apache /var/www/html

EXPOSE 80   
# >>>>> !!!!!! Exporter part
EXPOSE 9253 
EXPOSE 9117 
# >>>>> !!!!!!

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
