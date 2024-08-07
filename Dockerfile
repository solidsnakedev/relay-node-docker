# syntax=docker/dockerfile:1
FROM ubuntu:22.04

# Install Cardano dependencies and tools
RUN apt-get update -y && \
  apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf liblmdb-dev -y && \
  apt-get install curl neovim -y

RUN mkdir src

# Set libsodium PATH
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install libsodium
RUN cd src && \
    git clone https://github.com/IntersectMBO/libsodium && \
    cd libsodium && \
    git checkout dbb48cc && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

#Install libsecp256k1
RUN cd src && \
    git clone https://github.com/bitcoin-core/secp256k1 && \
    cd secp256k1 && \
    git checkout ac83be33 && \
    ./autogen.sh && \
    ./configure --enable-module-schnorrsig --enable-experimental && \
    make && \
    make install

# Install BLST
RUN cd src && \
  git clone https://github.com/supranational/blst && \
  cd blst && \
  git checkout v0.3.10 && \
  ./build.sh
RUN cat <<EOF > src/blst/libblst.pc 
  prefix=/usr/local
  exec_prefix=\${prefix}
  libdir=\${exec_prefix}/lib
  includedir=\${prefix}/include

  Name: libblst
  Description: Multilingual BLS12-381 signature library
  URL: https://github.com/supranational/blst
  Version: 0.3.10
  Cflags: -I\${includedir}
  Libs: -L\${libdir} -lblst
EOF
RUN cd src/blst && \
  cp libblst.pc /usr/local/lib/pkgconfig/ && \
  cp bindings/blst_aux.h bindings/blst.h bindings/blst.hpp  /usr/local/include/ && \
  cp libblst.a /usr/local/lib

# Install cardano-node and cardano-cli
ARG TAG
RUN <<EOT
    [ -z ${TAG} ] \
    && URL=$(curl -s https://api.github.com/repos/IntersectMBO/cardano-node/releases/latest | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url') \
    || URL=$( curl -s https://api.github.com/repos/IntersectMBO/cardano-node/releases/tags/${TAG} | jq -r '.assets[] | select(.name | contains("linux")) | .browser_download_url')

    cd src && \
    wget -cO - ${URL} > cardano-node.tar.gz && \
    tar -xvf cardano-node.tar.gz &&
    mv ./bin/cardano-node /usr/local/bin &&
    mv ./bin/cardano-cli /usr/local/bin
EOT

# Delete src folder
RUN rm -r /src

# Get latest config files
RUN wget -P /node/configuration \
    https://book.world.dev.cardano.org/environments/mainnet/byron-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/shelley-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/alonzo-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/conway-genesis.json \
    https://book.world.dev.cardano.org/environments/mainnet/config.json

# Change config to save them in /node/log/node.log file instead of stdout
RUN sed -i 's/StdoutSK/FileSK/' /node/configuration/config.json && \
    sed -i 's/stdout/\/node\/logs\/node.log/' /node/configuration/config.json && \
    sed -i 's/\"TraceBlockFetchDecisions\": false/\"TraceBlockFetchDecisions\": true/' /node/configuration/config.json && \
    sed -i 's/\"127.0.0.1\"/\"0.0.0.0\"/' /node/configuration/config.json

# Block producer node IP Address
ARG BLOCKPRODUCING_IP
# Block producer port
ARG BLOCKPRODUCING_PORT

RUN <<EOT
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
    }' > /node/configuration/topology.json
EOT


# Set network for cardano-cli commands
ENV NETWORK="--mainnet"

# Set mainnet magic number
ENV MAGIC_NUMBER=764824073

# Set path location
ENV NODE_HOME=/node
ENV POOL_KEYS=${NODE_HOME}/pool-keys
ENV DATA=${NODE_HOME}/data
ENV CONFIGURATION=${NODE_HOME}/configuration

# Set node socket evironment for cardano-cli
ENV CARDANO_NODE_SOCKET_PATH="/node/ipc/node.socket"

# Create folders
RUN mkdir -p /node/ipc /node/logs /node/configuration

# Copy scripts
COPY cardano-scripts/ /usr/local/bin

# Set executable permits
RUN /bin/bash -c "chmod +x /usr/local/bin/*.sh"

# Run cardano-node at the startup
CMD [ "/usr/local/bin/run-cardano-node.sh" ]
