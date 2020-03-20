#!/bin/bash

NETWORKID="n-J7NT5J6KUFEWRDCR3AHFOH4KRI"
MEMBERID="m-GZZTFKPX7NHT3PVJSK3EWIE4NQ"
ACCOUNTAWS="759857925977"
PROPOSALID="p-6LFJJ43O2ZCCNGUZTD2IS67VKM"
STACKNAMEBC="network-fullhybrid"
STACKNAMEADDMEMBER="member-2-network"
BLOCKCHAINVPCENDPOINT=""

# Create a network blockchain with one member and two peer nodes
aws cloudformation deploy --stack-name $STACKNAMEBC --template-file createNetworkBlockchain.yaml --capabilities CAPABILITY_NAMED_IAM --region us-east-1

# Get network id
NETWORKID=$(aws cloudformation describe-stacks --stack-name $STACKNAMEBC --query 'Stacks[0].Outputs[?OutputKey==`NetworkId`].OutputValue' --output text)

# Get Member Id
MEMBERID=$(aws managedblockchain list-members --network-id $NETWORKID --query 'Members[0].Id' --output text)

# create a proposal of invitation for a new member
aws managedblockchain create-proposal --network-id $NETWORKID --member-id $MEMBERID --actions Invitations=[{Principal=$ACCOUNTAWS}]

# get pending proposal id
PROPOSALID=$(aws managedblockchain list-proposals --network-id $NETWORKID --query 'Proposals[?Status==`PENDING`] | [0].ProposalId' --output text)

# Vote on a proposal for approve
aws managedblockchain vote-on-proposal --network-id $NETWORKID --proposal-id $PROPOSALID --voter-member-id $MEMBERID --vote "YES"

# Query invitation pending for join
INVITATIONID=$(aws managedblockchain list-invitations --query 'Invitations[?Status==`PENDING`] | [0].InvitationId' --output text)

# Add other member with an invitation
aws cloudformation deploy --stack-name $STACKNAMEADDMEMBER --template-file createMemberToNetwork.yaml --capabilities CAPABILITY_NAMED_IAM --region us-east-1 --parameter-overrides InvitationId=$INVITATIONID

# Create a KeyPair for EC2 for Client Node
aws ec2 create-key-pair --key-name fullhybrid-client-member1-keypair --region us-east-1 --query 'KeyMaterial' --output text > fullhybrid-client-member1-keypair.pem

# Get Network VPC Endpoint
BLOCKCHAINVPCENDPOINT=$(aws managedblockchain get-network --network-id $NETWORKID --query 'Network.VpcEndpointServiceName' --output text)

# add Fabric Client Node with Role, SecurityGroup, VPC, Subnet, InternetGateway, etc
aws cloudformation deploy --stack-name fullhybrid-client-member1 --template-file fabricClientNodeFirstMember.yaml --capabilities CAPABILITY_NAMED_IAM --region us-east-1 --parameter-overrides KeyName=fullhybrid-client-member1-keypair BlockchainVpcEndpointServiceName=$BLOCKCHAINVPCENDPOINT


######################### Inside the container EC2 #################################

# Update the tls certificate
aws s3 cp s3://us-east-1.managedblockchain/etc/managedblockchain-tls-chain.pem  /home/ec2-user/managedblockchain-tls-chain.pem

# Download images docker For explorer. Note that versión depends of Framework versión network
# Visit for more information: https://github.com/hyperledger/blockchain-explorer
docker pull hyperledger/explorer:0.3.7.1
docker pull hyperledger/exporer-db:0.3.7.1

# Install node v8.x
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install lts/carbon
nvm use lts/carbon
sudo yum install gcc-c++ -y

## Configure environment vars on instance EC2

## Enroll on network

## Create the channel

## Install Chaincode

## Install SDK

## Configure explorer