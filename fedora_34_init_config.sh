#!/bin/bash

# This script is used to configure a new Fedora 34 server for use with the Fedora 34 Docker image.
# It installs the necessary packages, sets up the firewall, and configures the network.

# Install necessary packages
sudo dnf install -y epel-release
sudo dnf install -y firewalld
sudo dnf install -y iptables-services
sudo dnf install -y net-tools
sudo dnf install -y wget
sudo dnf install -y curl
sudo dnf install -y git
sudo dnf install -y java-17-openjdk-devel
sudo dnf install -y java-17-openjdk
sudo dnf install -y maven
sudo dnf install -y postgresql-server
sudo dnf install -y postgresql-contrib
sudo dnf install -y postgresql
sudo dnf install -y nodejs
sudo dnf install -y nginx

# Set up firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Set up Java
sudo alternatives --set java /usr/lib/jvm/java-17-openjdk/bin/java
sudo update-alternatives --config java
sudo alternatives --set javac /usr/lib/jvm/java-17-openjdk/bin/javac
sudo update-alternatives --config javac


export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin
export JAVA_OPTS="-Xms512m -Xmx1024m"
export MAVEN_OPTS="-Xms512m -Xmx1024m"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# these parameters are gonna be used by application.properties
# DB_USERNAME = $pgsql_username
# DB_PASSWORD = $pgsql_password
# DB_HOST = localhost
# DB_PORT = 5432
# DB_NAME = $pgsql_database
# DB_URL = jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME

# set java alternatives
sudo alternatives --set java /usr/lib/jvm/java-17-openjdk/bin/java
sudo update-alternatives --config java
sudo alternatives --set javac /usr/lib/jvm/java-17-openjdk/bin/javac
sudo update-alternatives --config javac

# Nginx : Reverse Proxy CONFIG
sudo cp /home/vagrant/parsparand-reporter-application/src/main/resources/nginx.conf /etc/nginx/nginx.conf
# vi /etc/nginx/nginx.conf
  # server {
  #     listen 80;
   #     server_name pph.srv.local;
   #     location / {
   #       proxy_pass http://${IPADDRESS}:${PORT};
   #       proxy_set_header Host $host;
   #       proxy_set_header X-Real-IP $remote_addr;
   #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   #       proxy_set_header X-Forwarded-Proto $scheme;
   #     }
   #server {
#     listen 443 ssl;
   #     server_name pph.srv.local;
   #     ssl_certificate /etc/nginx/ssl/nginx.crt;
   #     ssl_certificate_key /etc/nginx/ssl/nginx.key;
   #     location /
   #       proxy_pass http://$IPADDRESS:$PORT;
   #       proxy_set_header Host $host;
   #       proxy_set_header X-Real-IP $remote_addr;
   #       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   #       proxy_set_header X-Forwarded-Proto $scheme;
   #


#postgressql 15
# USERNAME = pph
# PASSWORD = pph@123
# DATABASE = parsparand_db
# sudo -u postgres psql -c "CREATE USER pph WITH PASSWORD 'pph@123';"
# sudo -u postgres psql -c "CREATE DATABASE parsparand_db;"
# sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE parsparand_db TO pph;"
# sudo -u postgres psql -c "ALTER USER pph WITH SUPERUSER;"

sudo postgresql-setup initdb
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo -u postgres psql -c "CREATE USER pph WITH PASSWORD 'pph@123';"
sudo -u postgres psql -c "CREATE DATABASE parsparand_db;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE parsparand_db TO pph;"
sudo -u postgres psql -c "ALTER USER pph WITH SUPERUSER;"

# git config
git config --global user.name "mehdiyazdan"
git config --global user.email "yazdanparast.ubuntu@gmail.com"
git config --global credential.helper store
git config --global color.ui true
git config --global core.editor "vim"



# clone spring boot application from github
# Clone using the web URL. https://github.com/mehdiyazdan-git/parsparand-reporter-application.git
git clone https://github.com/mehdiyazdan-git/parsparand-reporter-application.git
# build the project
mvn clean install
# run the project
java -jar target/parsparand-reporter-application-0.0.1-SNAPSHOT.jar
# build a daemon to run the project
sudo cp /home/vagrant/parsparand-reporter-application/target/parsparand-reporter-application-0.0.1-SNAPSHOT.jar /usr/local/bin/parsparand-reporter-application.jar
sudo cp /home/vagrant/parsparand-reporter-application/parsparand-reporter-application.service /etc/systemd/system/parsparand-reporter-application.service
sudo systemctl daemon-reload
sudo systemctl enable parsparand-reporter-application
sudo systemctl start parsparand-reporter-application
# clone reactjs application from github
# Clone using the web URL. https://github.com/mehdiyazdan-git/parsparand-reporter-application-web.git

# first create a directory for the reactjs application
sudo mkdir /home/vagrant/reactjs
# then clone the reactjs application
git clone https://github.com/mehdiyazdan-git/parsparand-reporter-application-web.git
# then move the reactjs application to the created directory
sudo mv /home/vagrant/parsparand-reporter-application-web /home/vagrant/reactjs/parsparand-reporter-application-web
# then change the owner of the reactjs application to vagrant
sudo chown -R vagrant:vagrant /home/vagrant/reactjs/parsparand-reporter-application-web
# then change the permission of the reactjs application to 755
sudo chmod -R 755 /home/vagrant/reactjs/parsparand-reporter-application-web
# build the reactjs application
npm install
npm run build
# then start the reactjs application
sudo npm start
# then start the reactjs application as a daemon
sudo cp /home/vagrant/reactjs/parsparand-reporter-application-web/parsparand-reporter-application-web.service /etc/systemd/system/parsparand-reporter-application-web.service
sudo systemctl daemon-reload
sudo systemctl enable parsparand-reporter-application-web
sudo systemctl start parsparand-reporter-application-web


