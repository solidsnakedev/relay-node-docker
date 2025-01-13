#!/usr/bin/env bash

set -e

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}$(date +'%Y-%m-%d %H:%M:%S') - $1${NC}"
}

error_exit() {
    echo -e "${RED}$(date +'%Y-%m-%d %H:%M:%S') - ERROR: $1${NC}" >&2
    exit 1
}

log "Removing existing node/configuration directory"
rm -rf $(pwd)/node/configuration || error_exit "Failed to remove existing node/configuration directory"

log "Creating node/configuration directory"
mkdir -p $(pwd)/node/configuration || error_exit "Failed to create node/configuration directory"

log "Downloading latest config files"
wget -q -P $(pwd)/node/configuration \
    https://book.world.dev.cardano.org/environments/mainnet/byron-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/shelley-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/alonzo-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/conway-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/config.json || error_exit "Failed to download config files"

sed -i 's/\"TraceBlockFetchDecisions\": false/\"TraceBlockFetchDecisions\": true/' $(pwd)/node/configuration/config.json &&
    sed -i 's/\"127.0.0.1\"/\"0.0.0.0\"/' $(pwd)/node/configuration/config.json || error_exit "Failed to modify config.json"

log "Setting topology"

# Block producer node IP Address
BLOCKPRODUCING_IP=$1
# Block producer port
BLOCKPRODUCING_PORT=$2

jq -n --arg block_producer_ip "$BLOCKPRODUCING_IP" --arg block_producer_port "$BLOCKPRODUCING_PORT" '{
        "bootstrapPeers": [
            {"address": "backbone.cardano.iog.io", "port": 3001},
            {"address": "backbone.mainnet.emurgornd.com", "port": 3001},
            {"address": "backbone.mainnet.cardanofoundation.org", "port": 3001}
        ],
        "localRoots": [
            {
                "accessPoints": [
                    {"address": $block_producer_ip, "port": ($block_producer_port | tonumber)}
                ],
                "advertise": false,
                "valency": 1
            }
        ],
        "publicRoots": [
            {
                "accessPoints": [
                    {"address": "backbone.cardano.iog.io", "port": 3001},
                    {"address": "backbone.mainnet.emurgornd.com", "port": 3001},
                    {"address": "backbone.mainnet.cardanofoundation.org", "port": 3001}
                ],
                "advertise": false
            }
        ],
        "useLedgerAfterSlot": 99532743
    }' >$(pwd)/node/configuration/topology.json

log "Setup completed successfully"