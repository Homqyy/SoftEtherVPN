# SoftEtherVPN on Docker

仓库源码：[Homqyy/SoftEtherVPN](https://github.com/Homqyy/SoftEtherVPN)

基本仓库：[SoftEtherVPN/SoftEtherVPN:master](https://github.com/SoftEtherVPN/SoftEtherVPN)

特性差异：

- [x] 支持自动构建镜像: `linux/amd64`, `linux/arm64`
- [ ] 不限制区域对路由的配置
- [ ] 日志显示IP地址

## 支持的镜像

- [homqyy/softethervpn-server](https://hub.docker.com/r/homqyy/softethervpn-server)
- [homqyy/softethervpn-client](https://hub.docker.com/r/homqyy/softethervpn-client)
- [homqyy/softethervpn-bridge](https://hub.docker.com/r/homqyy/softethervpn-bridge)

## 运行方式

运行`vpncmd`以对 vpnclient/vpnserver/vpnbridge 进行管理：

```bash
docker exec -it <your_container_name> /vpn/bin/vpncmd
```

### Docker

Server:

```bash
docker run -d --rm --name vpn-server \
  -v vpnserver-db:/vpn/db \
  -v /etc/localtime:/dev/localtime:ro \
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

Client:

```bash
docker run -d --rm --name vpn-client \
  -v vpnclient-db:/vpn/db \
  -v /dev/net/tun:/dev/net/tun \
  -v /etc/localtime:/dev/localtime:ro \
  --cap-add NET_ADMIN \
  homqyy/softethervpn-client
```

Bridge:

```bash
docker run -d --rm --name vpn-bridge \
  -v vpnbridge-db:/vpn/db \
  -v /etc/localtime:/dev/localtime:ro \
  --cap-add NET_ADMIN \
  --cap-add SYSLOG \
  homqyy/softethervpn-bridge
```

### Compose

Server:

```yml
version: '3'

services:
  vpn-server:
    image: homqyy/softethervpn-server
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
      - "vpnserver-db:/vpn/db"

volumes:
    vpnserver-db:
```

Client:

```yml
version: '3'

services:
  vpn-client:
    image: homqyy/softethervpn-client
    cap_add:
      - NET_ADMIN
    restart: always
    volumes:
      - "/dev/net/tun:/dev/net/tun"
      - "/etc/localtime:/etc/localtime:ro"
      - "vpnclient-db:/vpn/db"

volumes:
    vpnclient-db:
```

Bridge:

```yml
version: '3'

services:
  vpn-bridge:
    image: homqyy/softethervpn-bridge
    cap_add:
      - NET_ADMIN
      - SYSLOG
    restart: always
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "vpnbridge-db:/vpn/db"

volumes:
    vpnbridge-db:
```
