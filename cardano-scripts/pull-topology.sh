#!/bin/bash
BLOCKPRODUCING_IP=194.163.158.69
BLOCKPRODUCING_PORT=6000
curl -s -o /node/configuration/topology.json "https://api.clio.one/htopology/v1/fetch/?max=6&customPeers=${BLOCKPRODUCING_IP}:${BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2"
