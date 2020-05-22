#!/bin/bash

# Crear TX inicial de canal de aplicación
configtxgen -profile ChannelsApp -outputCreateChannelTx testdev.tx -channelID testdev
# Crear TX de definción de peer ancla
configtxgen -profile ChannelsApp -outputAnchorPeersUpdate telefonicaAnchors.tx -channelID testdev -asOrg TELEFONICA
# Crear canal de aplicación
peer channel create -o orderer0.catalyst.telefonica.com:7050 -c testdev --tls --cafile $ORDERER_CA_TLS_CERT -f testdev.tx
# Unir el peer al canal
peer channel join -b testdev.block
# actualizar canal nuevo con el peer ancla
peer channel update -o orderer0.catalyst.telefonica.com:7050 -c testdev --tls --cafile $ORDERER_CA_TLS_CERT -f telefonicaAnchors.tx
# Obtener el bloque genesis
peer channel fetch 0 genesis.block -o orderer0.catalyst.telefonica.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT -c testdev
# unir los demás peer con el siguiente comando teniendo las variables de entorno con un admin
peer channel join -b genesis.block