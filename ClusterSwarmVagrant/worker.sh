    docker swarm join --token SWMTKN-1-11m87jst8p9td4ayppq2fhnapx4rtmhm93fkh7qjnn712meudy-6umjuu0b5ptuhthz8m3ldg45d 192.168.56.10:2377
docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine
