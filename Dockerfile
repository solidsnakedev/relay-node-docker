FROM ubuntu:latest

# Install Cardano dependencies
RUN apt-get update -y && \
    apt-get install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf liblmdb-dev curl vim -y

RUN mkdir src

RUN TAG=$(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest | jq -r .tag_name) && \
    cd src && \
    wget -cO - https://github.com/input-output-hk/cardano-node/releases/download/${TAG}/cardano-node-${TAG}-linux.tar.gz > cardano-node.tar.gz && \
    tar -xvf cardano-node.tar.gz && \
    mv cardano-node /usr/local/bin && \
    mv cardano-cli /usr/local/bin

# Install libsodium
RUN cd src && \
    git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout dbb48cc && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

# Update libsodium PATH
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

#Install libsecp256k1
RUN cd src && \
    git clone https://github.com/bitcoin-core/secp256k1 && \
    cd secp256k1 && \
    git checkout ac83be33 && \
    ./autogen.sh && \
    ./configure --enable-module-schnorrsig --enable-experimental && \
    make && \
    make install

# Delete src folder
RUN rm -r /src

# Get latest config files
RUN wget -P /node/configuration \
    https://raw.githubusercontent.com/input-output-hk/cardano-world/master/docs/environments/mainnet/byron-genesis.json \
    https://raw.githubusercontent.com/input-output-hk/cardano-world/master/docs/environments/mainnet/shelley-genesis.json \
    https://raw.githubusercontent.com/input-output-hk/cardano-world/master/docs/environments/mainnet/alonzo-genesis.json \
    https://raw.githubusercontent.com/input-output-hk/cardano-world/master/docs/environments/mainnet/conway-genesis.json

COPY config.json /node/configuration

# Change config to save them in /node/log/node.log file instead of stdout
RUN sed -i 's/StdoutSK/FileSK/' /node/configuration/config.json && \
    sed -i 's/stdout/\/node\/logs\/node.log/' /node/configuration/config.json && \
    sed -i 's/\"TraceBlockFetchDecisions\": false/\"TraceBlockFetchDecisions\": true/' /node/configuration/config.json && \
    sed -i 's/\"TraceMempool\": true/\"TraceMempool\": false/' /node/configuration/config.json && \
    sed -i 's/\"127.0.0.1\"/\"0.0.0.0\"/' /node/configuration/config.json

# Block producer node IP Address
ARG BLOCKPRODUCING_IP
# Block producer port
ARG BLOCKPRODUCING_PORT

RUN echo  "{\n" \
          "   \"localRoots\": [\n" \
          "         {\n" \
          "           \"accessPoints\": [\n" \
          "               { \"address\": \"${BLOCKPRODUCING_IP}\", \"port\": ${BLOCKPRODUCING_PORT} }\n" \
          "             ],\n" \
          "           \"advertise\": false,\n" \
          "           \"valency\": 1\n" \
          "         }\n" \
          "       ],\n" \
          "   \"publicRoots\": [\n" \
          "         {\n" \
          "           \"accessPoints\": [\n" \
          "               {\n" \
          "                 \"address\": \"relays-new.cardano-mainnet.iohk.io\",\n" \
          "                 \"port\": 3001\n" \
          "               }\n" \
          "             ],\n" \
          "           \"advertise\": false\n" \
          "         }\n" \
          "       ],\n" \
          "   \"useLedgerAfterSlot\": 84916732\n" \
          "}\n" \
          > /node/configuration/topology.json

# Set node socket evironment for cardano-cli
ENV CARDANO_NODE_SOCKET_PATH="/node/ipc/node.socket"

# Set mainnet magic number
ENV MAGIC_NUMBER=764824073

# Create keys, ipc, data, scripts, logs folders
RUN mkdir -p /node/ipc /node/logs

# Copy scripts
COPY cardano-scripts/ /usr/local/bin

# Set executable permits
RUN /bin/bash -c "chmod +x /usr/local/bin/*.sh"

# Run cardano-node at the startup
CMD [ "/usr/local/bin/run-cardano-node.sh" ]
