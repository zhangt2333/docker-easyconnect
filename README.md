# docker-easyconnect

让深信服开发的**非自由**的 EasyConnect 代理软件运行在 docker 中，并开放 Socks5 供宿主机连接以使用代理。

* Debian 10 一行命令安装 Docker:
```
 apt update \
   && apt-get -y install apt-transport-https ca-certificates curl software-properties-common \
   && curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | apt-key add - \
   && add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/debian $(lsb_release -cs) stable" \
   && apt-get -y update \
   && apt-get -y install docker-ce
```


* 运行下面的指令，会自动下载 docker 镜像并创建容器。之后让流量使用 socks://ip:1080 即是使用 VPN 啦:
```
 docker run -it \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  -p 1080:1080 \
  -e CLI_OPTS="-d VPN地址 -u 账号 -p 密码" \
  zhangt2333/docker-easyconnect:cli
```