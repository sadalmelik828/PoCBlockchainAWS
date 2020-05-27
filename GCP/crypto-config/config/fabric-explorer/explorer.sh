#!/bin/sh

## Crea usuario fabric
sudo useradd -m -d /home/fabric -s /bin/bash fabric
# Asigna password
sudo passwd fabric
## Asigna permisos de sudo al usuario
sudo usermod -aG sudo fabric
## inicia sesión con usuario fabric
su - fabric
## instalar GO
sudo apt install golang
## Configura las variables de entorno para GO
echo 'export GOPATH=$HOME/go' | tee -a ~/.bashrc
echo 'export GOBIN=$GOPATH/bin' | tee -a ~/.bashrc
source ~/.bashrc
# Descarga los ejemplos de fabric y los binarios excepto las imagenes docker
curl -sSL https://bit.ly/2ysbOFE | bash -s -- -d
# copia los binarios al path del sistema
sudo cp ~/fabric-samples/bin/* /usr/local/bin/
# Descarga Fabric-CA binarios
go get -u github.com/hyperledger/fabric-ca/cmd/...
# copia binarios de fabric-ca al path del sistema
sudo cp $GOBIN/* /usr/local/bin/
# Install nodeJS
sudo apt install nodejs
# Install npm
sudo apt install npm
# Install PostgreSQL
 sudo apt install postgresql postgresql-contrib
# Descargar fuentes de Hyperledger Explorer
git clone https://github.com/hyperledger/blockchain-explorer.git
# Install jq
sudo apt install jq
# Editar archivo ~/blockchain-explorer/app/explorerconfig.json y cambiar datos de conexión a DB
# crear base de datos
sudo -u postgres ~/blockchain-explorer/app/persistence/fabric/postgreSQL/db/createdb.sh
# Editar archivo ~/blockchain-explorer/blockchain-explorer/app/platform/fabric/config.json
# descargar dependencias de app
npm install