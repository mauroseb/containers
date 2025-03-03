# Chef-Server Containerfile
FROM docker.io/ubuntu:22.04

ARG IMAGE_CREATE_DATE
ARG IMAGE_VERSION
ARG IMAGE_VERSION_COMMIT

ENV USER_ID=1000 \
    APP=chef-server \
    CHEF_SERVER_VERSION=$IMAGE_VERSION \
    CHEF_SERVER_COMMIT=$IMAGE_VERSION_COMMIT \
    CHEF_SERVER_PORT=443 \
	container=docker \
    SUMMARY="Chef_Infra_server_in_a_container"


LABEL maintainer="mauro.oddi@gmail.com" \
      name="$APP" \
      build-date=$IMAGE_CREATE_DATE \
      version=$IMAGE_VERSION \
      summary="$SUMMARY" \
      usage="podman run -d --name chef-server-1 -e PG_HOST=192.168.0.1 -e PG_PORT=5432 -e PG_USER=admin -e PG_PASSWORD=verysecret -e OS_HOST=192.168.0.2 -e OS_USERNAME=admin -e OS_PASSWORD=verysecret -e OS_PORT=9200 -p 443:443 chef-server:$IMAGE_VERSION" \
      commit="$IMAGE_VERSION_COMMIT" \
      io.k8s.description="$SUMMARY" io.k8s.display-name="$APP" \
      io.openshift.non-scalable="false" io.openshift.tags="$APP" \
      org.opencontainers.image.title="Chef Infra Server" \
      org.opencontainers.image.description="Chef Infra Server" \
      org.opencontainers.image.authors="Mauro S. Oddi" \
      org.opencontainers.image.created=$IMAGE_CREATE_DATE \
      org.opencontainers.image.version=$IMAGE_VERSION \
      org.opencontainers.image.url="https://github.com/mauroseb/containers/chef-infra-server/Containerfile" \
      org.opencontainers.image.source="https://github.com/chef/chef-server" \
      org.opencontainers.image.vendor="Mauro Oddi" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /tmp

COPY chef-server-$IMAGE_VERSION-amd64.deb .

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends iproute2 systemd systemd-sysv systemd-cron dbus dbus-user-session && \
    apt-get clean && \
    dpkg -i /tmp/chef-server-$CHEF_SERVER_VERSION-amd64.deb && \
    rm -rf /var/lib/apt/lists/ && \
    rm /tmp/chef-server-$IMAGE_VERSION-amd64.deb

WORKDIR /etc/opscode

COPY chef-server.rb /etc/opscode/chef-server.rb
COPY first-run.sh log-forward.sh /usr/local/bin/
COPY chef-server-init.service chef-server-log-forward.service /etc/systemd/system/

RUN chown -R ${USER_ID}:0 /etc/opscode/ && \
    chmod +x /usr/local/bin/first-run.sh && \
    chmod +x /usr/local/bin/log-forward.sh && \
    ln -sf /etc/systemd/system/chef-server-init.service /etc/systemd/system/multi-user.target.wants/ && \
    ln -sf /etc/systemd/system/chef-server-log-forward.service /etc/systemd/system/multi-user.target.wants/

STOPSIGNAL SIGRTMIN+3

EXPOSE $CHEF_SERVER_PORT

CMD ["/lib/systemd/systemd", "--default-standard-output=journal+console", "--default-standard-error=journal+console", "--show-status=true" ]
  
