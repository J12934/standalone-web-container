### Standalone web application container
How to provide configurations for a web application without requiring an extra system for this propose

[//]: <> (divider)

### Introduction
Web assets are static. Therefore necessary configurations e.g. links to other systems must 
be compiled into the code at build time or could be dynamically loaded via a ReST resource at runtime. 

[//]: <> (divider)

### Where is the problem?
A hard coded configuration makes the configuration management very difficult and providing configurations via ReST 
requires an system which provides that.

[//]: <> (divider)

### The dilemma
Therefore both solutions not really applicable to small static web applications with only some configurable 
dependencies to other systems.
 
[//]: <> (divider)

*But is there are no other option?*

[//]: <> (divider)

**SURE!**

[//]: <> (divider)

### What do we can do?
A possible way is to combine both options and provide the configuration via the web server which serves the web 
application. For example a Nginx. 

[//]: <> (divider)

*Let's see how it could works!*

[//]: <> (divider)

### First of all
We need a minimal Nginx configuration which configures a static resource that provides the application configuration.
```
server {
    listen 80;
    server_name localhost;
    ...
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
    location /app-configuration {
        default_type application/json;
        return 200 '{\"url\":\"https://www.iteratec.de/\"}';
    }
}
```

[//]: <> (divider)
 
But in the end of the day this setup is really similar to compiling the configuration into the static assets. 

Some one must be hard coded the configuration into the web server.

[//]: <> (divider)

*What we want is to be able set the configuration properties dynamically at start up of the web server!* 

[//]: <> (divider)

### Make the resource dynamical
Let's change the Nginx configuration to the following and configure a placeholder as return value of the 
resource endpoint.
```
server {
    listen 80;
    server_name localhost;
    ...
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
    location /app-configuration {
        default_type application/json;
        return 200 ${APP_CONFIG};
    }
}
```

[//]: <> (divider)

### How do we can replace this on start up?
The configured placeholder will be not resolved out of the box. To do this let's take a look to the following 
Dockerfile. 

The important keyword is `envsubst`!  

[//]: <> (divider)
### Using variable substitution
With the command `envsubst` it's possible to replace the placeholder within the Nginx configuration with the value of
 identically named environment variable.
```dockerfile
FROM nginx:latest
ADD ./nginx-setup/default.conf /tmp/template.conf
ADD ./index.html /usr/share/nginx/html
EXPOSE 80
RUN     DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get -y install gettext-base \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
CMD envsubst < /tmp/template.conf \
    > /etc/nginx/conf.d/default.conf \
    && nginx -g 'daemon off;'
```
[//]: <> (divider)

### What will be happen?
If we build and run the docker container then the placeholder will be replaced with the environment variable
 and afterwards automatically served by the web server like a static resource. This behaviour repeats each time the 
 container will be restart.
 
[//]: <> (divider)
 
To get a running example e.g. use docker-compose.  
```yaml
version: '2'
services:
  web-container:
    build:
      context: ./
      dockerfile: Dockerfile
    ports:
      - "8001:80"
    environment:
      - APP_CONFIG='{"articleUrl":"content/article.md"}'
```

[//]: <> (divider)

### A short flashback
What must do we do to achieve a the standalone web application container?

[//]: <> (divider)

* define a custom web server configuration which provides a static resource with a placeholder that could be replaced
* write a Dockerfile which defines the replacement on web server start up
* run a Docker container and provides the environment variable for replacement on web server start up 

[//]: <> (divider)

### You want to see this in action?
 
Checkout [iteratec on GitHub](https://github.com/iteratec/standalone-web-container)


## ENJOY!
