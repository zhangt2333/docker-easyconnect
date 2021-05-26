#!/bin/bash

# From https://github.com/Hagb/docker-easyconnect

# 不支持 nftables 时使用 iptables-legacy
# 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
if { [ -z "$IPTABLES_LEGACY" ] && iptables-nft -L 1>/dev/null 2>/dev/null ;}
then
	update-alternatives --set iptables /usr/sbin/iptables-nft
	update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
else
	update-alternatives --set iptables /usr/sbin/iptables-legacy
	update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
fi

# 在虚拟网络设备 tun0 打开时运行 proxy 代理服务器
[ -n "$NODANTED" ] || (while true
do
sleep 5
[ -d /sys/class/net/tun0 ] && { chmod a+w /tmp ; su daemon -s /usr/sbin/danted; }
done
)&

# https://github.com/Hagb/docker-easyconnect/issues/20
# https://serverfault.com/questions/302936/configuring-route-to-use-the-same-interface-for-outbound-traffic-as-that-of-inbo
iptables -t mangle -I OUTPUT -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark
iptables -t mangle -I INPUT -m connmark ! --mark 0 -j CONNMARK --save-mark
iptables -t mangle -I INPUT -m connmark --mark 1 -j MARK --set-mark 1
iptables -t mangle -I INPUT -i eth0 -j CONNMARK --set-mark 1
(
IFS="
"
for i in $(ip route show); do
	IFS=' '
	ip route add $i table 2
done
ip rule add fwmark 1 table 2
)

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# 拒绝 tun0 侧主动请求的连接.
iptables -I INPUT -p tcp -j REJECT
iptables -I INPUT -i eth0 -p tcp -j ACCEPT
iptables -I INPUT -i lo -p tcp -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 删除深信服可能生成的一条 iptables 规则，防止其丢弃传出到宿主机的连接
# 感谢 @stingshen https://github.com/Hagb/docker-easyconnect/issues/6
( while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP 2>/dev/null ; done )&

ln -s /usr/share/sangfor/EasyConnect/resources/{conf_${EC_VER},conf}

sleep 1

while true
do
	/usr/share/sangfor/EasyConnect/resources/bin/ECAgent &
	sleep 1
	easyconn login -t autologin
	pidof svpnservice > /dev/null || bash -c "exec easyconn login $CLI_OPTS"
	while pidof svpnservice > /dev/null ; do
	       sleep 1
	done
	echo svpn stop!

	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall CSClient svpnservice 2> /dev/null
	kill %1 %2 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice 2> /dev/null
done
