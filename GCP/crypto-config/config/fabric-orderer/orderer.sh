#!/bin/sh

## Crea usuario fabric
sudo useradd -m -d /home/fabric -s /bin/bash -p fabric fabric
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
# Crear directorio de inscripción en Fabric-CA
mkdir -p ~/fabric-ca/clients/ca/orderers/orderer0.catalyst.telefonica.com
# Exportar variable para recibir MSP
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/orderers/orderer0.catalyst.telefonica.com
# Colocar en /etc/hosts los DNS del Fabric-CA, los demas orderers y los peers
# Inscribirse en el Fabric-CA
fabric-ca-client enroll -u http://orderer0.catalyst.telefonica.com:orderer0C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
# crear directorio para almacenar los archivos de configuración y MSP
sudo mkdir -p /etc/hyperledger/{fabric/config/catalyst.telefonica.com,msp/{orderers,peers,users},production}
# Cambiar de propietrario los directorios creados
sudo chown -R fabric:fabric /etc/hyperledger
# Cambiar los permisos de acceso
chmod -R 700 /etc/hyperledger
# copiar todos los certificados obtenido del enroll a los nuevos directorios
# Copiar los archivos de configuración ya revisados
# Generar bloque genesis para el canal del sistema
configtxgen -profile GenesisCatalyst -outputBlock configtx/genesis.block -channelID catalyst-sys-channel
# Iniciar el orderer manualmente para ver que todo quedó bien
orderer start
# Si se inició bien entonces se procede a crear el servicio en systemd
