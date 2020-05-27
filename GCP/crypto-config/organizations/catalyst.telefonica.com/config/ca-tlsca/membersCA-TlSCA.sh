#!/bin/sh

# catalyst.telefonica.com

##### Register users #####

## CA

# admin
fabric-ca-client register -d --id.name admin@catalyst.telefonica.com --id.secret adm1nC4t4ly5tT3l3f0n1ca --id.type admin --id.affiliation telefonica.catalyst --id.attrs '"hf.Registrar.Roles=client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert'
# admin 2
fabric-ca-client register -d --id.name admin2@catalyst.telefonica.com --id.type admin --id.secret admin2C4t4ly5tT3l3f0n1ca
# Client1
fabric-ca-client register -d --id.name client1@catalyst.telefonica.com --id.type client --id.secret client1C4t4ly5tT3l3f0n1ca
# Orderer0
fabric-ca-client register -d --id.name orderer0.catalyst.telefonica.com --id.type orderer --id.affiliation telefonica.catalyst --id.secret orderer0C4t4ly5tT3l3f0n1ca
# Orderer1
fabric-ca-client register -d --id.name orderer1.catalyst.telefonica.com --id.type orderer --id.affiliation telefonica.catalyst --id.secret orderer1C4t4ly5tT3l3f0n1ca
# Peer0
fabric-ca-client register -d --id.name peer0.catalyst.telefonica.com --id.type peer --id.affiliation telefonica.catalyst --id.secret peer0C4t4ly5tT3l3f0n1ca
# Peer1
fabric-ca-client register -d --id.name peer1.catalyst.telefonica.com --id.type peer --id.affiliation telefonica.catalyst --id.secret peer1C4t4ly5tT3l3f0n1ca

## TLSCA

# Admin
fabric-ca-client register -d --id.name admin@catalyst.telefonica.com --id.secret tlsAdm1nC4t4ly5tT3l3f0n1c4 --id.type admin --id.affiliation telefonica.catalyst --id.attrs '"hf.Registrar.Roles=client",hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert' --caname tlsca.catalyst.telefonica.com
# Orderer0
fabric-ca-client register -d --id.name orderer0.catalyst.telefonica.com --id.type orderer --id.affiliation telefonica.catalyst --id.secret orderer0TLSC4t4ly5tT3l3f0n1ca --caname tlsca.catalyst.telefonica.com
# Orderer1
fabric-ca-client register -d --id.name orderer1.catalyst.telefonica.com --id.type orderer --id.affiliation telefonica.catalyst --id.secret orderer1TLSC4t4ly5tT3l3f0n1ca --caname tlsca.catalyst.telefonica.com
# Peer0
fabric-ca-client register -d --id.name peer0.catalyst.telefonica.com --id.type peer --id.affiliation telefonica.catalyst --id.secret peer0TLSC4t4ly5tT3l3f0n1ca --caname tlsca.catalyst.telefonica.com
# Peer1
fabric-ca-client register -d --id.name peer1.catalyst.telefonica.com --id.type peer --id.affiliation telefonica.catalyst --id.secret peer1TLSC4t4ly5tT3l3f0n1ca --caname tlsca.catalyst.telefonica.com


##### Enroll Users #####

# CA

# orderer0
mkdir -p ~/fabric-ca/clients/ca/orderers/orderer0.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/orderers/orderer0.catalyst.telefonica.com
fabric-ca-client enroll -u http://orderer0.catalyst.telefonica.com:orderer0C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
## edito archivo de config y borro el msp
## vuelvo y enroll
# Admin
mkdir -p ~/fabric-ca/clients/ca/users/admin@catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/users/admin@catalyst.telefonica.com
fabric-ca-client enroll -u http://admin@catalyst.telefonica.com:adm1nC4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
# Admin2
mkdir -p ~/fabric-ca/clients/ca/users/admin2@catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/users/admin2@catalyst.telefonica.com
fabric-ca-client enroll -u http://admin2@catalyst.telefonica.com:admin2C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
# Client1
mkdir -p ~/fabric-ca/clients/ca/users/client1@catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/users/client1@catalyst.telefonica.com
fabric-ca-client enroll -u http://client1@catalyst.telefonica.com:client1C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
# Peer0
mkdir -p ~/fabric-ca/clients/ca/peers/peer0.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/peers/peer0.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer0.catalyst.telefonica.com:peer0C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054
# Peer1
mkdir -p ~/fabric-ca/clients/ca/peers/peer1.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/ca/peers/peer1.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer1.catalyst.telefonica.com:peer1C4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054

# TLSCA

# Orderer0
mkdir -p ~/fabric-ca/clients/tlsca/orderers/orderer0.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/orderers/orderer0.catalyst.telefonica.com
fabric-ca-client enroll -u http://orderer0.catalyst.telefonica.com:orderer0TLSC4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054 --caname tlsca.catalyst.telefonica.com --enrollment.profile tls
# Admin
mkdir -p ~/fabric-ca/clients/tlsca/users/admin@catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/users/admin@catalyst.telefonica.com
fabric-ca-client enroll -u http://admin@catalyst.telefonica.com:tlsAdm1nC4t4ly5tT3l3f0n1c4@catalyst.telefonica.com:7054 --caname tlsca.catalyst.telefonica.com --enrollment.profile tls
# Peer0
mkdir -p ~/fabric-ca/clients/tlsca/peers/peer0.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/peers/peer0.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer0.catalyst.telefonica.com:peer0TLSC4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054 --caname tlsca.catalyst.telefonica.com --enrollment.profile tls
# Peer1
mkdir -p ~/fabric-ca/clients/tlsca/peers/peer1.catalyst.telefonica.com
export FABRIC_CA_CLIENT_HOME=~/fabric-ca/clients/tlsca/peers/peer1.catalyst.telefonica.com
fabric-ca-client enroll -u http://peer1.catalyst.telefonica.com:peer1TLSC4t4ly5tT3l3f0n1ca@catalyst.telefonica.com:7054 --caname tlsca.catalyst.telefonica.com --enrollment.profile tls