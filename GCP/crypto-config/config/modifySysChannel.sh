#!/bin/bash

# Variables que se deben cargar
export FABRIC_CFG_PATH=/etc/hyperledger/fabric/config/catalyst.telefonica.com
export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/admin@catalyst.telefonica.com/msp
export CORE_PEER_LOCALMSPID=TELEFONICAMSP
export CORE_PEER_ID=AdminTelefonica
export CORE_PEER_ADDRESS=peer0.catalyst.telefonica.com:7051
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/msp/peers/peer0.catalyst.telefonica.com/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/msp/peers/peer0.catalyst.telefonica.com/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/msp/peers/peer0.catalyst.telefonica.com/tls/ca.crt
export ORDERER_CA_TLS_CERT=/etc/hyperledger/msp/orderers/orderer0.catalyst.telefonica.com/tls/ca.crt

# Extraer la configuración actual del canal
peer channel fetch config currentConfig.pb -o orderer0.catalyst.telefonica.com:7050 -c catalyst-sys-channel --tls --cafile $ORDERER_CA_TLS_CERT
# convertir la configuración a formato json
configtxlator proto_decode --input currentConfig.pb --type common.Block --output currentConfig.json
# formatear la configuración
cat currentConfig.json | jq . > currentConfig-formated.json
# Extraer solo los datos de configuración
jq .data.data[0].payload.data.config currentConfig-formated.json > currentConfig-extracted.json
##
## INICIO
## Los siguentes comandos agregan la nueva organización a diferentes secciones de la configuración del canal.
## Cada uno es un paso para completar la adición de la nueva org
## Se requiere tener los archivos: 
## - Configuración en formato json de la otra organización
## - Información de los orderers de la otra organización
##
#  Orderer-channel-group
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Orderer\":{\"groups\":{\"NTT\":.[1]}}}}}" currentConfig-extracted.json NTT-formated.json > modifiedConfig-v1.json
# Consortium-channel-group (NOTE:: before command remove tag Endpoints from org.json) (Only for sys channel)
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Consortiums\":{\"groups\":{\"SampleConsortium\":{\"groups\": {\"NTT\":.[1]}}}}}}}" currentConfig-extracted.json NTT-formated.json > modifiedConfig-v1.json
# Application-channel-group (NOTE:: before command remove tag Endpoints from org.json) (Only for application channels)
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Application\":{\"groups\": {\"ATC\":.[1]}}}}}" currentConfig-extracted.json ATC-formated.json > modifiedConfig-v1.json
# Consenters-channel-group (Only for sys channel)
jq ".channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [$(cat ATCconsenter.json)]" currentConfig-extracted.json > modifiedConfig-v1.json
# Orderer-address-list (Only for sys channel)
jq ".channel_group.values.OrdererAddresses.value.addresses += [\"orderer0.catalyst.atc.com:7050\"]" currentConfig-extracted.json > modifiedConfig-v1.json
##
## FIN
##
# Convertir los datos de configuración actual del canal a bloque
configtxlator proto_encode --input currentConfig-extracted.json --type common.Config --output currentConfig-extracted.pb
# Convertir la modificación de la configuración a bloque
configtxlator proto_encode --input modifiedConfig-v1.json --type common.Config --output modifiedConfig-v1.pb
# Calcular la diferencia entre lo actual y lo cambiado
configtxlator compute_update --channel_id catalyst-sys-channel --original currentConfig-extracted.pb --updated modifiedConfig-v1.pb --output configUpdate-v1.pb
# Convertir la diferencia de cambios resultante a json
configtxlator proto_decode --input configUpdate-v1.pb --type common.ConfigUpdate --output configUpdate-v1.json
# formatear a json
cat configUpdate-v1.json | jq . > configUpdate-v1-formated.json
# Agregar header de configuración a cambios actuales
echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"catalyst-sys-channel\", \"type\":2}},\"data\":{\"config_update\":"$(cat configUpdate-v1-formated.json)"}}}" | jq . > configUpdate-v1-envelope.json
# Convertir cambios actuales a bloque
configtxlator proto_encode --input configUpdate-v1-envelope.json --type common.Envelope --output configUpdate-v1-envelope.pb
##
## El siguiente comando es para firmar el bloque de cambios del canal. Esa tarea la debe hacer un admin de las organizaciones ya incluidas o la organización se va a incluir en el canal en caso de que sea la segunda organización.
## - Orderer-channel-group - Este se debe usar a partir de la inclusión de la tercera organización y se debe obtener la mayoria de firmas
## - consortium-channel-group
## - consenters-channel-group
## - orderer-address-list
peer channel signconfigtx -f configUpdate-v1-envelope.pb
# Firmar y actualizar el bloque de configuración del canal
peer channel update -f configUpdate-v1-envelope-signedATC.pb -o orderer0.catalyst.telefonica.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT -c catalyst-sys-channel

# Crear archivo con información de o los orderers de la organización a incluir en el canal para el paso de consenters-channel-group
echo "{\"client_tls_cert\":\"$(cat <PATH_CRT_TLS_ORDERER> | base64 -w 0)\",\"host\":\"orderer0.catalyst.ntt.com\",\"port\":7050,\"server_tls_cert\":\"$(cat <PATH_CRT_TLS_ORDERER> | base64 -w 0)\"}" > NTTconsenter.json


## Get updated config
peer channel fetch config updatedConfig.pb -o orderer0.catalyst.telefonica.com:7050 -c catalyst-sys-channel --tls --cafile $ORDERER_CA_TLS_CERT
configtxlator proto_decode --input updatedConfig.pb --type common.Block --output updatedConfig.json
cat updatedConfig.json | jq . > updatedConfig-formated.json
jq .data.data[0].payload.data.config updatedConfig-formated.json > updatedConfig-extracted.json

## Iniciar el orderer con el bloque resultante del siguiente comando:
## Este proceso se realiza justo despues del paso consenters-channel-group
## Antes de iniciar el orderer de la nueva organización, se debe asegurar que todos los orderers tengan visibilidad entre ellos
cp updatedConfig.pb latestConfigSysChannel.block
