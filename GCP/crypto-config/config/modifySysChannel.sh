#!/bin/bash
FABRIC_CFG_PATH=(ruta de config del peer)
CORE_PEER_MSPCONFIGPATH=(msp del admin user)
CORE_PEER_LOCALMSPID=(igual que al de la organización)
CORE_PEER_ID=(id del cliente)
CORE_PEER_ADDRESS=(igual que el peer)
CORE_PEER_TLS_ENABLED=(igual que el peer)
CORE_PEER_TLS_CERT_FILE=(igual que el peer)
CORE_PEER_TLS_KEY_FILE=(igual que el peer)
CORE_PEER_TLS_ROOTCERT_FILE=(igual que el peer)
ORDERER_CA_TLS_CERT=(ruta al ca del tls del orderer)

FABRIC_LOGGING_SPEC=INFO
CORE_CHAINCODE_KEEPALIVE=10


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

peer channel fetch config currentConfig.pb -o orderer0.catalyst.telefonica.com:7050 -c catalyst-sys-channel --tls --cafile $ORDERER_CA_TLS_CERT
configtxlator proto_decode --input currentConfig.pb --type common.Block --output currentConfig.json
cat currentConfig.json | jq . > currentConfig-formated.json
jq .data.data[0].payload.data.config currentConfig-formated.json > currentConfig-extracted.json
#  Orderer-channel-group
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Orderer\":{\"groups\":{\"ATC\":.[1]}}}}}" currentConfig-extracted.json ATC-formated.json > modifiedConfig-v1.json
# Consortium-channel-group (NOTE:: before command remove tag Endpoints from ATC.json)
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Consortiums\":{\"groups\":{\"SampleConsortium\":{\"groups\": {\"ATC\":.[1]}}}}}}}" currentConfig-extracted.json ATC-formated.json > modifiedConfig-v1.json
# Consenters-channel-group
jq ".channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [$(cat ATCconsenter.json)]" currentConfig-extracted.json > modifiedConfig-v1.json
# Orderer-address-list
jq ".channel_group.values.OrdererAddresses.value.addresses += [\"orderer0.catalyst.atc.com:7050\"]" currentConfig-extracted.json > modifiedConfig-v1.json
configtxlator proto_encode --input currentConfig-extracted.json --type common.Config --output currentConfig-extracted.pb
configtxlator proto_encode --input modifiedConfig-v1.json --type common.Config --output modifiedConfig-v1.pb
configtxlator compute_update --channel_id catalyst-sys-channel --original currentConfig-extracted.pb --updated modifiedConfig-v1.pb --output configUpdate-v1.pb
configtxlator proto_decode --input configUpdate-v1.pb --type common.ConfigUpdate --output configUpdate-v1.json
cat configUpdate-v1.json | jq . > configUpdate-v1-formated.json
echo "{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"catalyst-sys-channel\", \"type\":2}},\"data\":{\"config_update\":"$(cat configUpdate-v1-formated.json)"}}}" | jq . > configUpdate-v1-envelope.json
configtxlator proto_encode --input configUpdate-v1-envelope.json --type common.Envelope --output configUpdate-v1-envelope.pb
# Must be used on Consortium-channel-group, orderer-consenters-list and orderer-address-list by other org
peer channel signconfigtx -f configUpdate-v1-envelope.pb
peer channel update -f configUpdate-v1-envelope.pb -o orderer0.catalyst.telefonica.com:7050 --tls --cafile $ORDERER_CA_TLS_CERT -c catalyst-sys-channel

# Create file with information about orderer of other ORG for orderer-consenters-list
echo "{\"client_tls_cert\":\"$(cat <PATH_CRT_TLS_ORDERER> | base64 -w 0)\",\"host\":\"orderer0.catalyst.atc.com\",\"port\":7050,\"server_tls_cert\":\"$(cat <PATH_CRT_TLS_ORDERER> | base64 -w 0)\"}" > ATCconsenter.json


## Get updated config
peer channel fetch config updatedConfig.pb -o orderer0.catalyst.telefonica.com:7050 -c catalyst-sys-channel --tls --cafile $ORDERER_CA_TLS_CERT
configtxlator proto_decode --input updatedConfig.pb --type common.Block --output updatedConfig.json
cat updatedConfig.json | jq . > updatedConfig-formated.json
jq .data.data[0].payload.data.config updatedConfig-formated.json > updatedConfig-extracted.json