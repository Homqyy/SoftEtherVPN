# SoftEtherVPN on Docker

## Supported Images

- [homqyy/softethervpn-server](https://hub.docker.com/r/homqyy/softethervpn-server)
- [homqyy/softethervpn-client](https://hub.docker.com/r/homqyy/softethervpn-client)
- [homqyy/softethervpn-bridge](https://hub.docker.com/r/homqyy/softethervpn-bridge)

## How to Run

### Docker

Server:

```bash
docker run -d --rm --name vpn-server \
  -v vpnserver-db:/vpn/db \
  -p 443:443/tcp \
  -p 992:992/tcp \
  -p 1194:1194/udp \
  -p 5555:5555/tcp \
  -p 500:500/udp \
  -p 4500:4500/udp \
  -p 1701:1701/udp \
  --cap-add NET_ADMIN \
  --cap-add SYSLOG \
  homqyy/softethervpn-server
```

### Compose

```yml
version: '3'

services:
  softether:
    image: softethervpn/vpnserver
    cap_add:
      - NET_ADMIN
      - SYSLOG
    restart: always
    ports:
      - 444:443
      - 992:992
      - 1194:1194/udp
      - 5555:5555
      - 500:500/udp
      - 4500:4500/udp
      - 1701:1701/udp
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "vpnserver-db:/vpn/db"

volumes:
    vpnserver-db:
```
