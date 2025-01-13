# Relay node instructions

## Before building

### Add new user to remote server

```bash
useradd -m -s /bin/bash cardano
```

```bash
passwd cardano
```

```bash
usermod -aG sudo cardano
```


### Copy ed25519 public keys from local to remote server 

```bash
ssh-copy-id -i $HOME/.ssh/<keyname>.pub cardano@server.public.ip.address

```
### Update `sshd_config` file

```bash
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
```bash
sudo sshd -t
```

### Restart sshd service
```bash
sudo systemctl restart sshd
```

Remember to replace <ip-address> in ./prometheus/prometheus.yml with the proper ip addresses

## Build cardano node docker image

* replace `<block-producer-ip-address>` with the IP Address of the block producer node
* replace `<block-producer-port>` with the Port number of the block producer node

```bash
./setup-configuration.sh <block-producer-ip-address> <block-producer-port>
```

## Upgrade Node

```bash
docker compose down
```

Modify `docker-compose.yml` image
```yaml
services:
  cardano-node-relay:
    image: ghcr.io/intersectmbo/cardano-node:10.1.4
```
```bash
docker compose up -d
```

## Execute commands
```bash
docker exec -it cardano-node-relay cardano-cli query tip --mainnet
```
