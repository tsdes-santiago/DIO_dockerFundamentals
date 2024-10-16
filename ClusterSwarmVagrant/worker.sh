    docker swarm join --token <Gerado automaticamente pelo script master> 192.168.56.10:2377
docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine
