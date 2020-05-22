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
#
mkdir -p ~/fabric-ca/clients/ca/peers/peer1.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/peers/peer1.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer1.catalyst.telefonica.com:peer1C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
#
mkdir -p ~/fabric-ca/clients/tlsca/peers/peer1.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/peers/peer1.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer1.catalyst.telefonica.com:peer1TLSC4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054 --caname tlsca.catalyst.telefonica.com --enrollment.profile tls
# crear directorio para almacenar los archivos de configuración y MSP
sudo mkdir -p /etc/hyperledger/{fabric/config/catalyst.telefonica.com,msp/{orderers,peers,users},production}
# Cambiar de propietrario los directorios creados
sudo chown -R fabric:fabric /etc/hyperledger
# Cambiar los permisos de acceso
chmod -R 700 /etc/hyperledger
# instalar llave para couchdb
curl -L https://couchdb.apache.org/repo/bintray-pubkey.asc | sudo apt-key add -
# agregar apt source couchdb (change for versión of ubuntu codename)
echo "deb https://apache.bintray.com/couchdb-deb focal main" | sudo tee -a /etc/apt/sources.list
# Actualizar paquetes
sudo apt update
# install couchdb
sudo apt install couchdb
# Crear nuevo usuario admin
curl -X PUT http://admin:peer1TLSC4t4ly5tT3l3f0n1ca@127.0.0.1:5984/_node/_local/_config/admins/peer1 -d '"peer1C4t4ly5tT3l3f0n1ca"'
# activar opción users_db_security
sudo sed -i 's/users_db_security_editable = false/users_db_security_editable = true/' /opt/couchdb/etc/default.ini
# Reiniciar servicio couchdb
sudo systemctl restart couchdb.service
# 
sudo cat > /etc/systemd/system/fabric-peer1.service << EOF
# Service definition for Hyperledger fabric peer server
[Unit]
Description=hyperledger fabric Peer - Peer0/Telefonica of hyperledger fabric
Documentation=https://hyperledger-fabric.readthedocs.io/
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
Restart=on-failure
Environment=FABRIC_LOGGING_SPEC=INFO
Environment=FABRIC_CFG_PATH=/etc/hyperledger/fabric/config/catalyst.telefonica.com
Environment=CORE_LOGGING_PEER=info
Environment=CORE_CHAINCODE_LOGGING_LEVEL=info
ExecStart=/usr/local/bin/peer node start
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fabric-peer1.catalyst.telefonica.com
[Install]
WantedBy=multi-user.target
EOF
## Crear regla para redireccionar log del servicio
sudo cat > /etc/rsyslog.d/80-fabric-peer1.catalyst.telefonica.com.conf << EOF
if $programname == 'fabric-peer1.catalyst.telefonica.com' then /var/log/fabric-peer1.catalyst.telefonica.com.log
& stop
EOF
# crear archivo de log
sudo touch /var/log/fabric-peer1.catalyst.telefonica.com.log
# Cambiar permisos de log
sudo chown syslog:adm /var/log/fabric-peer1.catalyst.telefonica.com.log
# Reiniciar el servicio syslog
sudo systemctl restart syslog
## Activar el servicio
sudo systemctl enable fabric-peer1.service
## Iniciar el servicio
sudo systemctl start fabric-peer1.service
## Ver el estado del servicio
sudo systemctl -l status fabric-peer1.service
