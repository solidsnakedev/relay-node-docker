# Relay node instructions

## Before building

### Add new user to remote server

```
useradd -m -s /bin/bash cardano
```
```
passwd cardano
```
```
usermod -aG sudo cardano
```


### Copy ed25519 public keys from local to remote server 

```
ssh-copy-id -i $HOME/.ssh/<keyname>.pub cardano@server.public.ip.address

```
### Update sshd_config file

```
sed -i '/ChallengeResponseAuthentication/d' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
sed -i '/PermitEmptyPasswords/d' /etc/ssh/sshd_config

echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
```

### Validate sshd config
```
sudo sshd -t
```

### Restart sshd service
```
sudo systemctl restart sshd
```

Remember to replace <ip-address> in ./prometheus/prometheus.yml with the proper ip addresses

## Build cardano node docker image

* replace `<block-producer-ip-address>` with the IP Address of the block producer node
* replace `<block-producer-port>` with the Port number of the block producer node

```
DOCKER_BUILDKIT=1 docker compose build \
    --build-arg BLOCKPRODUCING_IP=<block-producer-ip-address> \
    --build-arg BLOCKPRODUCING_PORT=<block-producer-port>
```

## Upgrade Node

```
$ docker compose down
```
```
$ DOCKER_BUILDKIT=1 docker compose build \
    --build-arg BLOCKPRODUCING_IP=<blockproducing-ip-address> \
    --build-arg BLOCKPRODUCING_PORT=<blockproducing-port>
```
or 
```
$ DOCKER_BUILDKIT=1 docker compose build cardano-node-relay \
    --no-cache \
    --build-arg BLOCKPRODUCING_IP=<blockproducing-ip-address> \
    --build-arg BLOCKPRODUCING_PORT=<blockproducing-port>
```


## Installing Crontab
Inside relay-node docker container

```
docker exec -it cardano-node-relay bash
```

```
apt install cron
```

Edit crontab file
```
crontab -e
```

Add following instructions
```
33 * * * * /usr/local/bin/topologyUpdater.sh
```
