### Standalone Web Application Container - Konfguration ohne zusätzliches Backend bereitstellen

Jeder Web-Entwickler kennt wahrscheinlich das leidige Problem - woher bezieht man am besten die nötige Konfiguration für die zu entwickelnde Web Applikation? 


#### Das Dilemma

Besonders in der heutigen Zeit mit steigender Anzahl an Mirco-Frontends stellt sich die Frage, wie man diesem Problem entgegen tritt. Ein wachsender Hype sind die "Backend for Frontends" (BFF), welche jeweils dediziert einem Frontend zugewiesen sind und für dieses maßgeschneidert Daten und Konfigurationen liefern. Doch gerade bei schlanken Mirco-Frontends besteht selten der Bedarf der Datenvorverarbeitung und somit interagieren diese kleinen Backend Systeme lediglich als Fassade vor einem ohnehin bestehenden Api-Gateway. 

Fazit: Nur um Konfigurationen für eine Web Applikationen bereitzustellen, macht es eigentlich keinen Sinn ein BFF zu implementieren, zu betreiben und zu warten. Doch wie geht's besser? Gibt es keine Möglichkeit die Konfigurationen dynamisch bereitzustellen ohne ein extra System zu bauen?

#### Es gibt einen Ausweg

DOCH! Warum konfigurieren wir nicht den Web Server, welcher die Web Applikation ausliefert, so das dieser die nötigen Konfigurationen für die Web Applikation dynamisch unter einer festen ReST Resource anbietet! Ziel ist also ein Docker Container, welcher zum Startzeitpunkt eine gegebene Konfiguration entgegen nimmt und anschließend für die Web Applikation bereitstellt. Um dieses Ziel zu erreichen sind nur ein paar wenige Puzzle Teile nötig. Lasst uns schauen welche!

Starten wir mit der richtigen Konfiguration des Web Servers beispielsweise eines Nginx. Neben der Auslieferung der statischen Assets für die Web Applikation müssen wir zusätzlich dafür sorgen, dass eine Resource definiert wird, welche zur Laufzeit des Web Servers die Konfiguration für die Web Applikation ausliefert. Wichtig dabei ist, dass wir die Konfiguration erst dynamisch zum Container Startzeitpunkt festlegen wollen. Daher wird zunächst ein Platzhalter `${APP_CONFIG}` als Rückgabe definiert. Beispielhaft dafür ist die folgende `server.conf`.

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

Neben der richtigen Server Konfiguration wird zudem ein entsprechendes Dockerfile benötigt, welches den Web Application Container definiert und die statischen Assets mit dem konfigurierten Nginx Web Server "verheiratet". Ein entsprechendes Dockerfile erbt also vom Nginx Base Image, ersetzt die Nginx Standard-Konfiguration und fügt die statischen Resourcen der Web Applikation hinzu. So wie beispielsweise im folgenden Dockerfile.
```dockerfile
FROM nginx:latest
ADD ./nginx-setup/default.conf /etc/nginx/conf.d/default.conf
ADD ./index.html /usr/share/nginx/html
EXPOSE 80
```
Doch wie ersetzt man jetzt den eingangs erwähnten Platzhalter in der Nginx Konfiguration zum Container Startzeitpunkt? Dies geschieht natürlich nicht von Geisterhand. Wir nutzen dafür `envsubst`. Dieses Unix Tool ermöglicht es Platzhalter mit gleichnamigen Umgebungsvariablen zu ersetzen. Damit dies auch geschieht müssen wir entsprechend das Dockerfile erweitern. Wie im folgenden Beispiel ersichtlich müssen dafür ein paar zusätzliche Tools innerhalb des Containers installiert und anschließend die Ersetzung vorgenommen werden.

```
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

So weit so gut. Doch was passiert nun, wenn wir das Docker Image bauen und den Container starten? Legen wir doch für das Beispiel folgenden Docker-Compose Stack zugrunde.
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
      - APP_CONFIG='{"someConfigParam":"someConfigValue"}'
```
Mit dem Befehl `docker-compose build` können wir das Beispiel-Setup bauen. Zusätzlich definieren wir die Umgebungsvariable `APP_CONFIG` mit der entsprechenden Konfiguration für die Web Applikation in JSON Notation. Zur Buildzeit des Docker Images wird nun unter anderem durch die Installation von `gettext-base` sichergestellt, dass `envsubst` zur Laufzeit genutzt werden kann. Fahren wir nun das Setup mittels `docker-compose up` hoch und starten den Container wird durch `envsubst` der Platzhalter `${APP_CONFIG}` mit der definierten Umgebungsvariable ersetzt, das Ergebnis in die `default.conf` des Nginx Web Servers geschrieben und der Server gestartet. 

Durch diesen Kniff liefert unser Server unter der Resource `/app-configuration` die Konfiguration `{"someConfigParam":"someConfigValue"}` aus und bietet diese somit für die Web Applikation an.

#### Was sind die Vorteile?

Besonders für eigenständige und kleine Micro-Frontends bietet sich diese Vorgehensweise an. Bei gleichbleibender Flexibilität und starker Entkopplung zur Web Applikation wird kein zusätzliches Backend System benötigt. Auch ein zusätzlicher Buildprozess ist nicht zwingend nötig, da die Konfiguration über Umgebungsvariablen in den Container gereicht werden. Beispielsweise auf einer Kubernetes Umgebung können durch ein "Zero-Downtime" Deployment die Container rollierend ausgetauscht und somit ohne Ausfallzeit die Konfiguration für die Web Applikation geändert werden. Alles was man dafür benötigt ist eine modifizierte Web Server Konfiguration und ein intelligentes Dockerfile! 

Probiere es selbst mit unserem Beispiel bei [Github](https://github.com/iteratec/standalone-web-container). 
