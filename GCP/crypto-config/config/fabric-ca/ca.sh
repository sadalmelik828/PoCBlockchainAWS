#!/bin/sh

### Script para inicializar un server de Fabric-CA sin necesidad de contenedores Docker

## Crea usuario fabric
sudo useradd fabric
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
# Crea directorio de configuración del server Fabric-CA
mkdir -p ~/fabric-ca/server
export FABRIC_CA_HOME=~/fabric-ca/server
## crear los archivo de configuración inicial del server
fabric-ca-server init -b <user>:<passwd>
## Se configurarán 2 CA, una para el CA de la organización y la otra para el TLSCA de la organización
## Crear directorio para el TLSCA
mkdir -p ~/fabric-ca/server/tlsca.atc.catalyst.com
## Copiar la configuración de la CA por defecto y adecuar los valores según se requiera
cp ~/fabric-ca/server/*.yaml ~/fabric-ca/server/tlsca.atc.catalyst.com
## Genera archivo de servicio para systemd del Fabric CA
sudo cat > /etc/systemd/system/fabric-ca.service << EOF
# Service definition for Hyperledger fabric-ca server
[Unit]
Description=hyperledger fabric-CA server - Certificate Authority for hyperledger fabric
Documentation=https://hyperledger-fabric-ca.readthedocs.io/
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
Restart=on-failure
Environment=FABRIC_LOGGING_SPEC=INFO
Environment=FABRIC_CA_SERVER_HOME=/home/fabric/fabric-ca/server
RestartSec=1
User=fabric
ExecStart=/usr/local/bin/fabric-ca-server start -b <user>:<passwd> --cafiles /home/fabric/fabric-ca/server/tlsca.atc.catalyst.com/fabric-ca-server-config.yaml --cfg.identities.allowremove
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fabric-ca
[Install]
WantedBy=multi-user.target
EOF
## Crear regla para redireccionar log del servicio
sudo cat > /etc/rsyslog.d/80-fabric-ca.conf << EOF
if $programname == 'fabric-ca' then /var/log/fabric-ca.log
& stop
EOF
# crear archivo de log
sudo touch /var/log/fabric-ca.log
# Cambiar permisos de log
sudo chown syslog:adm /var/log/fabric-ca.log
# Reiniciar el servicio syslog
sudo systemctl restart syslog
## Activar el servicio
sudo systemctl enable fabric-ca.service
## Iniciar el servicio
sudo systemctl start fabric-ca.service
## Ver el estado del servicio
sudo systemctl -l status fabric-ca.service

###
### Generar certificados desde CA exclusiva para la organización
###

## Desde otra VM o incluso en la misma crear si no existe
mkdir -p ~/fabric-ca/clients/ca/admin
# establecer la variable de entorno
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/admin
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
## Si no se tiene una configuración inicial para el cliente de fabric-ca, se generara automatica con los valores por defecto
## Inscribir la identidad inicial, esto creará el directorio msp con los certificados de la identidad
fabric-ca-client enroll -u http://admin:atc2020adm1n@atc.catalyst.com:7054
## registrar otro admin para propositos de configuración desde otra maquina
fabric-ca-client register -d --id.name admin@atc.catalyst.com --id.secret adm1nC4t4ly5t --id.type admin --id.affiliation atc.catalyst --id.attrs '"hf.Registrar.Roles=client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert'
## Registrar orderers, peers o clients que se requieran
# orderer0
fabric-ca-client register -d --id.name orderer0.atc.catalyst.com --id.type orderer --id.affiliation atc.catalyst --id.secret orderer0ATCC4t4ly5t
# Registro de un peer
fabric-ca-client register -d --id.name peer0.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer0ATCC4t4ly5t
# peer1
fabric-ca-client register -d --id.name peer1.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer1ATCC4t4ly5t
## Registro de un user
fabric-ca-client register -d --id.name user1@atc.catalyst.com --id.secret user1C4t4ly5t --id.affiliation atc.catalyst --id.type client
## Desde la VM que va a ser peer, este comando genera el msp de dicho peer
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054
## lo mismo pasa para los usuarios cliente
fabric-ca-client enroll -u http://user1@atc.catalyst.com:user1C4t4ly5t@atc.catalyst.com:7054
## los mismo para el admin
fabric-ca-client enroll -u http://admin@atc.catalyst.com:adm1nC4t4ly5t@atc.catalyst.com:7054
# orderer0
fabric-ca-client enroll -u http://orderer0.atc.catalyst.com:orderer0ATCC4t4ly5t@atc.catalyst.com:7054


### 
### Generar certificados TLS desde otra CA exclusiva para TLS
###

## Desde otra VM o incluso en la misma del Fabric-CA server crear si no existe
mkdir -p ~/fabric-ca/clients/tlsca/admin
# establecer la variable de entorno
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/admin
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
### Registra la identidad inicial del TLSCA
fabric-ca-client enroll -u http://admin:tlscaATC2020adm1n@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com
### registrar los mismos usuarios del CA a excepción de los users - Esto se hace desde el server de Fabric-CA o desde el nodo donde inscribio el admin
## Admin
fabric-ca-client register -d --id.name admin@atc.catalyst.com --id.secret adm1nC4t4ly5t --id.type admin --id.affiliation atc.catalyst --id.attrs '"hf.Registrar.Roles=client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert' --caname tlsca.atc.catalyst.com
# orderer0
fabric-ca-client register -d --id.name orderer0.atc.catalyst.com --id.type orderer --id.affiliation atc.catalyst --id.secret orderer0ATCC4t4ly5tTLS --caname tlsca.atc.catalyst.com
# peer0
fabric-ca-client register -d --id.name peer0.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer0ATCC4t4ly5tTLS --caname tlsca.atc.catalyst.com
# peer1
fabric-ca-client register -d --id.name peer1.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer1ATCC4t4ly5tTLS --caname tlsca.atc.catalyst.com
# Inscribir los usuarios para obtener los certificados - Esto se deberia hacer desde la VM del orderer0
# admin
fabric-ca-client enroll -d -u http://admin@atc.catalyst.com:adm1nC4t4ly5t@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com --enrollment.profile tls
# orderer
fabric-ca-client enroll -d -u http://orderer0.atc.catalyst.com:orderer0ATCC4t4ly5tTLS@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com --enrollment.profile tls
# peer0 - Esto se hace desde la VM del peer0
fabric-ca-client enroll -d -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5tTLS@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com --enrollment.profile tls


###
### copia de certificados para crypto-config
###

# crea directorios con la estructura igual a la que genera el cryptogen
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/{ca,msp,peers,tlsca,users}
# Copia el certificado raíz del CA para dicha organización - (Información sensible - mantener la seguridad de acceso)
cp ~/fabric-ca/server/*.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/ca/ca.atc.catalyst.com-cert.pem
# Copia la llave privada del CA de la organización - (Información sensible - mantener la seguridad de acceso)
cp ~/fabric-ca/server/msp/keystore/*_sk ~/crypto-config/peerOrganizations/atc.catalyst.com/ca/priv_sk
# Crea directorio MSP de la organización
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/{admincerts,cacerts,tlscacerts}
# Copia el certificado raíz del CA al MSP de la organización
cp ~/crypto-config/peerOrganizations/atc.catalyst.com/ca/ca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/cacerts
# Copia el certificado raíz del TLSCA al MSP de la organización
cp ~/fabric-ca/server/tlsca.atc.catalyst.com/tlsca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/tlscacerts
## crear archivo config.yaml en la ruta ~/crypto-config/peerOrganizations/atc.catalyst.com/msp
cat > ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/config.yaml << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
### El siguiente proceso se repite por cada identidad (peer, orderer o client) que quiera agregar ###

# Crea directorio MSP de una identidad. En este caso un peer
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/{msp,tls}
## crear archivo config.yaml en la ruta ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
cat > ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp/config.yaml << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.atc.catalyst.com-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
# crea directorio para obtener el MSP de la identidad directo del Fabric-CA
mkdir -p ~/fabric-ca/clients/ca/peers/peer0.atc.catalyst.com
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
# Exporta la variable de configuración del Fabric-CA client a la misma ruta del directorio recien creado
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/peers/peer0.atc.catalyst.com
# Inscribe la identidad en el Fabric-CA. El server retorna los certificados de dicha identidad en el directorio MSP
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054
# copia los certificados del MSP de la identidad en la estructura crypto-config
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalyst.com/cacerts ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalyst.com/keystore ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalyst.com/signcerts ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
# Crea directorios adicionales en el MSP de la identidad
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp/{admincerts,tlscacerts}
# Copia el certificado raíz del TLSCA en el MSP de la identidad
cp ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/tlscacerts/tlsca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp/tlscacerts
# crea directorio para obtener el MSP de la identidad directo del TLSCA
mkdir -p ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalyst.com
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
# Exporta la variable de configuración del TLSCA client a la misma ruta del directorio recien creado
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/peers/peer0.atc.catalyst.com
# Inscribe la identidad en el TLSCA. El server retorna los certificados de dicha identidad en el directorio MSP
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com --enrollment.profile tls
## Copia el certificado de dicha identidad en el directorio tls
cp ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalyst.com/signcerts/*.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/server.crt
# Copia la llave privada de dicha identidad en el directorio tls
cp ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalyst.com/keystore/*_sk ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/server.key
# Copia el certificado raíz del TLSCA
cp ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/tlscacerts/tlsca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/ca.crt