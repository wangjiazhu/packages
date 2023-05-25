#!/bin/bash

# @Author: wjz
# @Email : 1072002783@qq.com
# @Blog  : https://blog.csdn.net/weixin_51720652
# @Func  : 部署DHCP服务器


# 安装DHCP服务软件
yum install dhcp -y
if [ $? -ne 0 ];then
	echo "DHCP服务软件安装失败！"
	exit 1
fi
echo "DHCP服务软件安装成功！"


# 备份dhcpd.conf配置文件，清空其中内容
cp /etc/dhcp/dhcpd.conf{,.bak}
cat >/etc/dhcp/dhcpd.conf <<EOF
subnet 192.168.72.0 netmask 255.255.255.0 {
  range 192.168.72.150 192.168.72.180;
  option domain-name-servers 114.114.114.114;
  option domain-name "dhcp.cn";
  option routers 192.168.72.1;
  option broadcast-address 192.168.72.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF


# 从终端获取IP地址、DHCP网络段及掩码、DHCP的地址范围、客户端获取IP后的域名地址
# 设置DHCP子网
read -p $'------------------------------\n请输入DHCP服务子网\neg: DHCP子网：192.168.1.0\nDHCP子网 >>> ' DHCP_SUBNET
sed -i "s|\(subnet\) \(.*\) \(netmask\)|\1 ${DHCP_SUBNET} \3|g" /etc/dhcp/dhcpd.conf

# 设置DHCP子网掩码
read -p $'------------------------------\n请输入DHCP服务子网的掩码(回车默认255.255.255.0)\nDHCP子网掩码 >>> ' DHCP_NETMASK
if [[ $DHCP_DNS == "" ]];then
	DHCP_NETMASK="255.255.255.0"
fi
sed -i "s|\(netmask\) \(.*\) \({\)|\1 ${DHCP_NETMASK} \3|g" /etc/dhcp/dhcpd.conf

# 设置DHCP服务提供的地址范围
read -p $'------------------------------\n请输入DHCP服务提供给客户机的IP地址范围\neg: DHCP服务IP地址范围 192.168.1.100 192.168.1.150\nDHCP服务IP地址范围 >>> ' DHCP_IP_RANGE
sed -i "s|\(.* range\) \(.*\);|\1 ${DHCP_IP_RANGE};|g" /etc/dhcp/dhcpd.conf

# 设置DHCP域名解析地址(即DNS，当客户端通过DHCP服务器获取到IP地址后，会默认使用此处配置的DNS)
read -p $'------------------------------\n请输入DHCP服务默认提供给客户机的DNS(回车默认DNS地址为114.114.114.114)\nDNS >>> ' DHCP_DNS
if [[ $DHCP_DNS == "" ]];then
	DHCP_DNS="114.114.114.114"
fi
sed -i "s|\(.*\) \(domain-name-servers\) \(.*\);|\1 \2 ${DHCP_DNS};|g" /etc/dhcp/dhcpd.conf

# 设置DHCP服务提供的默认网关(客户端通过DHCP服务获取到IP地址后，会默认通过该路由访问网络)
DEFAULT_ROUTE=$(echo $DHCP_SUBNET|awk 'BEGIN{FS=".";OFS="."}{print $1,$2,$3,"1"}')
read -p $'------------------------------\n'"请输入DHCP服务默认提供给客户机的路由(路由即网关，回车默认是$DEFAULT_ROUTE)"$'\n网关GATEWAY >>> ' DHCP_ROUTE
if [[ $DHCP_ROUTE == "" ]];then
	DHCP_ROUTE=$DEFAULT_ROUTE
fi
sed -i "s|\(.* routers\) \(.*\);|\1 ${DHCP_ROUTE};|g" /etc/dhcp/dhcpd.conf

# 设置DHCP服务提供的默认广播地址(客户端通过DHCP服务获取到Ip地址后，会默认使用该广播地址进行内网段通信)
DEFAULT_BROADCAST=$(echo $DHCP_SUBNET|awk 'BEGIN{FS=".";OFS="."}{print $1,$2,$3,"255"}')
read -p $'------------------------------\n'"请输入DHCP服务默认提供给客户机的广播地址(回车默认是$DEFAULT_BROADCAST)"$'\n广播地址BROADCAST >>> ' DHCP_BROADCAST
if [[ $DHCP_BROADCAST == "" ]];then
	DHCP_BROADCAST=$DEFAULT_BROADCAST
fi
sed -i "s|\(.* broadcast-address\) \(.*\);|\1 ${DHCP_BROADCAST};|g" /etc/dhcp/dhcpd.conf

systemctl restart dhcpd &>/dev/null
systemctl enable dhcpd &>/dev/null

if [ $? -ne 0 ];then
	exit 1
	echo "DHCP服务部署失败"
fi
echo "DHCP服务部署成功"
