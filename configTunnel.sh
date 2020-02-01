#!/bin/bash

###### 对端网络配置

# 对端公网 IP
ip_remote="59.110.174.253"

# 对端内网网段
ip_remote_vlan="192.168.20.0/24"


###### 本端网络配置

# 取公网 IP
ip_public=`curl http://members.3322.org/dyndns/getip`

# 取内网 IP
ip_private=`ifconfig  | grep "inet" | grep "192.168" | awk '{print $2}'`

# 取内网 IP 的第三段作为隧道名和配置文件名字的一部分
net_vlan=`ifconfig  | grep "inet" | grep "192.168" | awk '{print $2}' | awk -F "." '{print $3}'`

# 本地网段
subnet="192.168.59.0/24"

###### 秘钥
token="20150509"

###### 配置文件

# 更改 ipsec 配置文件
sed -i 's/#version 2/version 2/g' /etc/ipsec.conf 
sed -i '/protostack=netkey/a\        nat_traversal=yes\n        oe=off' /etc/ipsec.conf

# 创建隧道配置文件
echo """conn tunnel$net_vlan
        ike=3des-sha
        authby=secret
        phase2=esp
        phase2alg=3des-sha
        compress=no
        pfs=yes
        type=tunnel
        left=$ip_private
        leftid=$ip_public
        leftsubnet=$subnet
        leftnexthop=%defaultroute
        right=$ip_remote
        rightid=$ip_remote
        rightsubnet=$ip_remote_vlan
        rightnexthop=%defaultroute
        auto=start""" >> /etc/ipsec.d/tunnel"$net_vlan".conf

# 配置秘钥认证
echo "0.0.0.0 $ip_remote: PSK \"$token\"" >> /etc/ipsec.secrets 

systemctl restart ipsec
