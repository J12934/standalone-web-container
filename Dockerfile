FROM nginx:latest
ADD ./nginx-setup/default.conf /tmp/template.conf
ADD . /usr/share/nginx/html
EXPOSE 80
RUN     DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get -y install gettext-base \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
CMD envsubst < /tmp/template.conf > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
