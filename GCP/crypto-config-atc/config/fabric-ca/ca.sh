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
# Descarga los ejemplos de fabric y los binarios
curl -sSL https://bit.ly/2ysbOFE | bash -s -- -d
# copia los binarios al path del sistema
sudo cp ~/fabric-samples/bin/* /usr/local/bin/
# Descarga Fabric-CA binarios
go get -u github.com/hyperledger/fabric-ca/cmd/...
# copia binarios de fabric-ca al path del sistema
sudo cp $GOBIN/* /usr/local/bin/
# Crea directorio de configuración del server Fabric-CA
mkdir -p fabric-ca/server
export FABRIC_CA_HOME=/home/fabric/fabric-ca/server
## crear los archivo de configuración inicial del server con 2 instancias CA
## Una para el CA de la organización y la otra para el TLSCA de la organización
## No es necesario si ya se tiene los archivos de configuración previamente adecuados
fabric-ca-server init -b admin:atc2020adm1n --cafiles /home/fabric/fabric-ca/server/tlsca.atc.catalyst.com/fabric-ca-server-config.yaml
## modificar los valores de configuración en el archivo de configuración
sudo systemctl start fabric-ca.service

## Desde otra VM o incluso en la misma crear si no existe
mkdir -p ~/fabric-ca/clients/ca/admin
# establecer la variable de entorno
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/admin
## Si no se tiene una configuración inicial para el cliente de fabric-ca, se generara automatica con los valores por defecto
## Inscribir la identidad inicial, esto creará el directorio msp con los certificados de la identidad
fabric-ca-client enroll -u http://admin:atc2020adm1n@atc.catalyst.com:7054
## registrar otro admin para propositos de configuración desde otra maquina
fabric-ca-client register -d --id.name admin@atc.catalyst.com --id.secret adm1nC4t4ly5t --id.type admin --id.affiliation atc.catalyst --id.attrs '"hf.Registrar.Roles=peer,client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert'
## Registar el o los peer que se requieran
fabric-ca-client register -d --id.name peer0.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer0ATCC4t4ly5t
## Registrar el o los clientes que se requieran
fabric-ca-client register -d --id.name user1@atc.catalyst.com --id.secret user1C4t4ly5t --id.affiliation atc.catalyst --id.type client
## Desde la VM que va a ser peer, este comando genera el msp de dicho peer
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054
## lo mismo pasa para los usuarios cliente
fabric-ca-client enroll -u http://user1@atc.catalyst.com:user1C4t4ly5t@atc.catalyst.com:7054
## los mismo para el admin
fabric-ca-client enroll -u http://admin@atc.catalyst.com:adm1nC4t4ly5t@atc.catalyst.com:7054


### Los pasos anteriores de inscripción y registro de identidades incluida la inicial, se puede repetir para el CA de TLS
## Ademas de cambiar el valor de la variables de entorno FABRIC_CA_CLIENT_HOME, se debe añadir en los comandos la directiva --caname <nombre_del_ca>

### Registra la identidad inicial del TLSCA
fabric-ca-client enroll -u http://admin:tlscaATC2020adm1n@atc.catalyst.com:7054 --caname tlsca.atc.catalyst.com

### registrar los mismos usuarios del CA a excepción de los users - Esto se hace desde el server de Fabric-CA
## Admin
fabric-ca-client register -d --id.name admin@atc.catalyst.com --id.secret adm1nC4t4ly5t --id.type admin --id.affiliation atc.catalyst --id.attrs '"hf.Registrar.Roles=client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert' --caname tlsca.atc.catalyst.com
# orderer0
fabric-ca-client register -d --id.name orderer0.atc.catalyst.com --id.type orderer --id.affiliation atc.catalyst --id.secret orderer0ATCC4t4ly5tTLS --caname tlsca.atc.catalyst.com
# peer0
fabric-ca-client register -d --id.name peer0.atc.catalyst.com --id.type peer --id.affiliation atc.catalyst --id.secret peer0ATCC4t4ly5tTLS --caname tlsca.atc.catalyst.com
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

### El siguiente proceso se repite por cada identidad (peer, orderer o client) que quiera agregar ###

# Crea directorio MSP de una identidad. En este caso un peer
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/{msp,tls}
## crear archivo config.yaml en la ruta ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
# crea directorio para obtener el MSP de la identidad directo del Fabric-CA
mkdir -p ~/fabric-ca/clients/ca/peers/peer0.atc.catalist.com
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
# Exporta la variable de configuración del Fabric-CA client a la misma ruta del directorio recien creado
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/peers/peer0.atc.catalist.com
# Inscribe la identidad en el Fabric-CA. El server retorna los certificados de dicha identidad en el directorio MSP
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054
# copia los certificados del MSP de la identidad en la estructura crypto-config
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalist.com/cacerts ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalist.com/keystore ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
cp -rf ~/fabric-ca/clients/ca/peers/peer0.atc.catalist.com/signcerts ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp
# Crea directorios adicionales en el MSP de la identidad
mkdir -p ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp/{admincerts,tlscacerts}
# Copia el certificado raíz del TLSCA en el MSP de la identidad
cp ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/tlscacerts/tlsca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/msp/tlscacerts
# crea directorio para obtener el MSP de la identidad directo del TLSCA
mkdir -p ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalist.com
## Se debe copiar el archivo de configuración del Fabric-CA client en la ruta con las respectivas modificaciones
# Exporta la variable de configuración del TLSCA client a la misma ruta del directorio recien creado
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/peers/peer0.atc.catalist.com
# Inscribe la identidad en el TLSCA. El server retorna los certificados de dicha identidad en el directorio MSP
fabric-ca-client enroll -u http://peer0.atc.catalyst.com:peer0ATCC4t4ly5t@atc.catalyst.com:7054 --caname tlsca.atc.catalist.com
## Copia el certificado de dicha identidad en el directorio tls
cp ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalist.com/*.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/server.crt
# Copia la llave privada de dicha identidad en el directorio tls
cp ~/fabric-ca/clients/tlsca/peers/peer0.atc.catalist.com/keystore/*_sk ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/server.key
# Copia el certificado raíz del TLSCA
cp ~/crypto-config/peerOrganizations/atc.catalyst.com/msp/tlscacerts/tlsca.atc.catalyst.com-cert.pem ~/crypto-config/peerOrganizations/atc.catalyst.com/peers/peer0.atc.catalyst.com/tls/ca.crt