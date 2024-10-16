<h1>
    <a href="https://www.dio.me/">
     <img align="center" width="40px" src="https://hermes.digitalinnovation.one/assets/diome/logo-minimized.png"></a>
    <span> Formação Docker Fundamentals
</span>
</h1>

# :computer: Desafio de projeto: Definição de um Cluster Swarm Local com o Vagrant
Neste desafio de projeto iremos criar um Cluster Swarm local, utilizando máquinas virtuais, além, de aplicar nossos conhecimentos em Vagrant. Também vamos aprender uma forma de evitar as implementações manualmente, melhorando o desempenho dos desenvolvedores.

## PASSO A PASSO:

1. Criar um Vagrantfile com as definições de 4 máquinas virtuais. Sendo uma máquina com o nome de master e as outras com os nomes de node01, node02 e node03; 
2. Cada máquina virtual deverá ter um IP fixo; 
3. Todas as MV deverão possuir o Docker pré-instalado; 
4. A máquina com o nome de master deverá ser o nó manager do cluster. 
5. As demais máquinas deverão ser incluídas no cluster Swarm como Workers. 

[Github do instrutor](https://github.com/denilsonbonatti/docker-projeto2-cluster)

# :bulb: Solução do desafio 

Foi utilizado o vagrant com o virtualbox para gerar as máquinas virtuais.

Seguindo a aula e o github do instrutor para configurar o **Vagrantfile** e adicionei algumas modificações para sincronizar um volume de dados da maquina host com as guests e instalar e executar um container http.

## Arquivos de configuração

### Vagrantfile

#### Criação das 4 máquinas virtuais
```Ruby
# -*- mode: ruby -*-
# vi: set ft=ruby  :

machines = {
  "master" => {"memory" => "1024", "cpu" => "1", "ip" => "10", "image" => "bento/ubuntu-22.04"},
  "node01" => {"memory" => "1024", "cpu" => "1", "ip" => "11", "image" => "bento/ubuntu-22.04"},
  "node02" => {"memory" => "1024", "cpu" => "1", "ip" => "12", "image" => "bento/ubuntu-22.04"},
  "node03" => {"memory" => "1024", "cpu" => "1", "ip" => "13", "image" => "bento/ubuntu-22.04"}
}
```

#### Configuração das 4 máquinas virtuais

```Ruby
Vagrant.configure("2") do |config|

  machines.each do |name, conf|
```
Configurar port forwarding para acessar o servidor http:
```Ruby
    config.vm.synced_folder "data/", "/srv/"
    config.vm.network "forwarded_port", guest: 8080, host: 8080,
      auto_correct: true
```
```Ruby
config.vm.define "#{name}" do |machine|
      machine.vm.box = "#{conf["image"]}"
      machine.vm.hostname = "#{name}"
```
Ip fixo das máquinas:
```Ruby
      machine.vm.network "private_network", ip: "192.168.56.#{conf["ip"]}"
      machine.vm.provider "virtualbox" do |vb|
        vb.name = "#{name}"
        vb.memory = conf["memory"]
        vb.cpus = conf["cpu"]
        #vb.gui = true
      end
```
Retire o comentário acima em `vb.gui = true` para executar a interface gráfica do virtualbox e acompanhar a instalação e ver possíveis erros.

Executa o script **docker.sh**
```Ruby
      machine.vm.provision "shell", path: "docker.sh"
```
Executa o script no master
```Ruby
      if "#{name}" == "master"
        machine.vm.provision "shell", path: "master.sh"
```
Executa o script nos nodes
```Ruby
      else
        machine.vm.provision "shell", path: "worker.sh"
      end

    end
  end
end

```

### docker.sh

Instala o docker nas máquinas virtuais

```shell
#!/bin/bash
curl -fsSL https://get.docker.com | sudo bash
sudo curl -fsSL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker vagrant
```
### master.sh

Inicia o cluster swarm com a máquina virtual master como master.

```shell
#!/bin/bash
sudo docker swarm init --advertise-addr=192.168.56.10
```

Instala a imagem e executa o container do docker para o servidor hhtp **nginx**.
```shell
docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine
```

Cria o scrip **workers.sh** para adicionar os nós ao cluster
```shell
sudo docker swarm join-token worker | grep docker > /vagrant/worker.sh
echo "docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine" >> /vagrant/worker.sh
```

### worker.sh

Adiciona o nó ao cluster
```console
docker swarm join --token SWMTKN-1-11m87jst8p9td4ayppq2fhnapx4rtmhm93fkh7qjnn712meudy-6umjuu0b5ptuhthz8m3ldg45d 192.168.56.10:2377
```

Instala a imagem e executa o container do docker para o servidor hhtp **nginx**.
```console
docker run --name nginx-app -v /srv/website:/usr/share/nginx/html -p 8080:80 -d nginx:1-alpine
```

## Execução

Executando o comando `vagrant up` os cluster foram criados e o redirecionamento de portas configurados:

```console
$ vagrant up
==> master: Forwarding ports...
    master: 8080 (guest) => 8080 (host) (adapter 1)
    master: 22 (guest) => 2222 (host) (adapter 1)

==> node03: Forwarding ports...
    node03: 8080 (guest) => 2204 (host) (adapter 1)
    node03: 22 (guest) => 2205 (host) (adapter 1)

==> node02: Forwarding ports...
    node02: 8080 (guest) => 2202 (host) (adapter 1)
    node02: 22 (guest) => 2203 (host) (adapter 1)

==> node01: Forwarding ports...
    node01: 8080 (guest) => 2200 (host) (adapter 1)
    node01: 22 (guest) => 2201 (host) (adapter 1)
```

* Os arquivos do volume na máquina host foi sincronizado com as máquinas virtuais. (Pode-se fazer a conexão ssh com qualquer dos nós e verificar com o comando `$ cat /srv/website/index.html`)

* O servidor http nginx foi instalado e o container está em execução. (Pode-se fazer a conexão ssh com qualquer dos nós e verificar com o comando `$ docker ps`)

* O cluster foi configurado corretamente (`docker node ls` executado no master)

Abaixo os comandos executados na máquina virtual master:

```console
$ vagrant ssh master
vagrant@master:~$ cat /srv/website/index.html 
<!DOCTYPE html>
<html>
 
<head>
    <title>
        First Web Page
    </title>
</head>
 
<body>
    Hello World!
</body>

vagrant@master:~$ docker ps
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                     NAMES
3b10ea2095a6   nginx:1-alpine   "/docker-entrypoint.…"   11 minutes ago   Up 11 minutes   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   nginx-app

vagrant@master:~$ sudo su
root@master:/home/vagrant# docker node ls
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
r9i77t4srubtcqavi5vtrtq7m *   master     Ready     Active         Leader           27.3.1
q3d6e6ps792tqjr2eolr3tdgs     node01     Ready     Active                          27.3.1
slu46bq14xpw5j9hpixvy6kek     node02     Ready     Active                          27.3.1
jz0a0ijqswqbxyvvt35c4hnap     node03     Ready     Active                          27.3.1
```

## Remover as máquinas virtuais após execução
```console
$ vagrant destroy
```

# :beetle: Bugs

* Mesmo a configuração de portas parecendo OK (executar o comando no host com qualquer das portas redirecionadas dos guests):

```console
$ curl -i http://localhost:8080
HTTP/1.1 200 OK
Server: nginx/1.27.2
Date: Wed, 16 Oct 2024 14:29:56 GMT
Content-Type: text/html
Content-Length: 131
Last-Modified: Wed, 16 Oct 2024 14:08:35 GMT
Connection: keep-alive
ETag: "670fc8e3-83"
Accept-Ranges: bytes

curl: (18) transfer closed with 131 bytes remaining to read
```

Ao modificar o arquivo index.htm o `Content-Length`é modificado no retorno do comando acima, a página não é exibida no navegar. Talvez seja necessária mais alguma configuração de rede ou firewall.

* A versão atual do vagrant não é compatível com o virtualbox 7.1, foi necessário modificar o arquivo `/usr/bin/VBox` (Utilizo o linux) para funcionar. [Vagrant Issues](https://github.com/hashicorp/vagrant/issues/13501)

```
    VirtualBoxVM|virtualboxvm)
        exec "$INSTALL_DIR/VirtualBoxVM" "$@"
        ;;
    VBoxManage|vboxmanage)
    ########################
        if [[ $@ == "--version" ]]; then
           echo "7.0.0r164728"
        else
           exec "$INSTALL_DIR/VBoxManage" "$@"
        fi
        ;;
    ########################
    VBoxSDL|vboxsdl)
        exec "$INSTALL_DIR/VBoxSDL" "$@"
        ;;
```


