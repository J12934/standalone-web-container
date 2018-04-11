### Standalone web application container
How to provide configurations for a web application without requiring an extra system for this propose

[//]: <> (divider)

### The entry point
Imagine that we have a small web application which needs some configuration properties e.g. links to other systems.

[//]: <> (divider)

### Which possibilities do we have?
At least we have two possibilities to serve configuration data. 
* Compile the configuration directly into the app
* Load configuration via a ReST resource at runtime

[//]: <> (divider)

### Where is the problem?
A hard coded configuration makes the configuration management very difficult and providing configurations via ReST 
requires an system which provides that.

[//]: <> (divider)

### The dilemma
Therefore both solutions not really applicable to small web applications with only some configurable properties.
 
[//]: <> (divider)

*But is there are no other option?*

[//]: <> (divider)

**SURE!**

[//]: <> (divider)

### What do we can do?
We provide the configuration via the web server which serves the web application!

[//]: <> (divider)

*Let's see how it could works!*

[//]: <> (divider)

### What do we need?

Only a handful of peaces.
* A server configuration file (e.g. Nginx), ...
* ... a Dockerfile, ...
* ... perhaps docker-compose stack ...
* ... and at least some **magic**!

[//]: <> (divider)

### The web server configuration
Let's configure the web server and add a resource which provides the configuration. 
Take your eyes on the placeholder `${APP_CONFIG}`.
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

### The dockerfile
Now we must write a Dockerfile which bundles the web application into the web server.
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

### Where is the magic?
The placeholder in the Nginx configuration will be not resolved out of the box. For this we use `envsubst`!

[//]: <> (divider)

### What do we achieve with 'envsubst'?
`envsubst` is be able to replaces placeholder within files with the value of identically named environment variables.
```dockerfile
...
CMD envsubst < /tmp/template.conf \
    > /etc/nginx/conf.d/default.conf \
    && nginx -g 'daemon off;'
...
```

[//]: <> (divider)

### What will be finally happen?
If we build and run the docker container then the placeholder will be replaced with the environment variable
 and afterwards automatically served by the web server like a static resource.
 
[//]: <> (divider)
 
### Demonstrate it!
To get a running example we can use docker-compose.
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

If we start the docker container the Nginx configuration will be replaced and used to configure the starting Nginx!
```
server {
    ...
    location /app-configuration {
        default_type application/json;
        return 200 '{"articleUrl":"content/article.md"}';
    }
}
```

[//]: <> (divider)

### What are the benefits?

* We don't need an extra backend service which provides the configuration
* We don't need an extra build to change the configuration
* We can be easily modify and inject the configuration into the context using environment variables
* We can easily integrate this technique into a managed container platform like Kubernetes 

[//]: <> (divider)

### You want to try it yourself?
 
Checkout [iteratec on GitHub](https://github.com/iteratec/standalone-web-container)

## ENJOY!
