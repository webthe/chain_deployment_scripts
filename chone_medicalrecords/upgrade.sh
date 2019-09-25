#----------------------------------
#!/bin/bash
#
# Copyright, RoundSqr,  All Rights Reserved
#
# Author: Thej Kiran Bitta
#
# Upgrade medical chaincode
set -e

#CHAIN CODE DEFAULTS
CC_NAME="chone_medicalrecords";
#increment the version value
CC_VERSION="1.51";
CHANNEL_NAME="channelone";

echo "VERSION"
echo "$CC_VERSION"
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)

CC_SRC_LANGUAGE=${1:-"typescript"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`
if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang"  ]; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH=github.com/fabcar/go
elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH=/opt/gopath/src/github.com/fabcar/node
elif [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH=/opt/gopath/src/github.com/abeo/${CC_NAME}
	pushd $HOME/fabric-samples/chaincode/abeo/${CC_NAME}
	sudo rm -rf dist
	echo Compiling TypeScript code into JavaScript ...
	pushd $HOME/fabric-samples/chaincode/abeo/${CC_NAME}
	npm install
	npm run build
	popd
	echo Finished compiling TypeScript code into JavaScript
else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, javascript, and typescript
	exit 1
fi

cd $HOME/fabric-samples/basic-network

docker exec -e "CORE_PEER_LOCALMSPID=CLINIC1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/clinic1.abeo.com/users/Admin@clinic1.abeo.com/msp" cliclinic1 peer chaincode install -n "$CC_NAME" -v "$CC_VERSION" -p "$CC_SRC_PATH" -l "$CC_RUNTIME_LANGUAGE"
docker exec -e "CORE_PEER_LOCALMSPID=CLINIC1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/clinic1.abeo.com/users/Admin@clinic1.abeo.com/msp" cliclinic1 peer chaincode upgrade -o orderer.abeo.com:7050 -C "$CHANNEL_NAME" -n "$CC_NAME" -l "$CC_RUNTIME_LANGUAGE" -v "$CC_VERSION" -c '{"Args":[]}' -P "OR ('CLINIC1MSP.member')"

sleep 10
