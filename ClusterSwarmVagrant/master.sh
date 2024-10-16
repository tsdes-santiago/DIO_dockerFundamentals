#!/bin/bash
sudo docker swarm init --advertise-addr=192.168.56.10
docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine
sudo docker swarm join-token worker | grep docker > /vagrant/worker.sh
echo "docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine" >> /vagrant/worker.sh