#!/bin/bash

set -xe

HOSTADDR="0.0.0.0"
PORT="6000"
TOPOLOGY="/node/configuration/topology.json"
CONFIG="/node/configuration/config.json"
DBPATH="/node/db"
SOCKETPATH="/node/ipc/node.socket"

/usr/local/bin/cardano-node run \
        --topology ${TOPOLOGY} \
        --database-path ${DBPATH} \
        --socket-path ${SOCKETPATH} \
        --host-addr ${HOSTADDR} \
        --port ${PORT} \
        --config ${CONFIG}
