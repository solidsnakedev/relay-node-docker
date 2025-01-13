#!/usr/bin/env bash

# Check if db directory exists and prompt for confirmation
DB_PATH="$(pwd)/node/db"
if [ -d "$DB_PATH" ]; then
    read -p "Warning: $DB_PATH exists. Do you want to remove it? (y/N) " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        sudo rm -rf "$DB_PATH"
        echo "Database directory removed."
    else
        echo "Aborted. Database directory was not removed."
        exit 1
    fi
fi

network="mainnet" # mainnet, preprod, or preview

export AGGREGATOR_ENDPOINT=https://aggregator.release-${network}.api.mithril.network/aggregator
export GENESIS_VERIFICATION_KEY=$(curl -s https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-${network}/genesis.vkey)
export SNAPSHOT_DIGEST=latest

mkdir -p $(pwd)/temp

if [ "$(uname -s)" == "Darwin" ]; then
    platform_mithril="macos-arm64"
else
    platform_mithril="linux-x64"
fi

mithril_version=2450.0
curl -L -o - https://github.com/input-output-hk/mithril/releases/download/${mithril_version}/mithril-${mithril_version}-${platform_mithril}.tar.gz |
    tar xz -C $(pwd)/temp mithril-client

chmod +x $(pwd)/temp/mithril-client

# Run client
$(pwd)/temp/mithril-client -vv cardano-db download --download-dir $(pwd)/node latest
