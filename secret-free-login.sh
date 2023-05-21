#!/bin/sh
source /etc/init.d/functions 

# 安装sshpass软件
yum install -y sshpass
if [ $? -eq 0 ];then
    action "sshpass install success!" /bin/true
else
    action "sshpass install failed!" /bin/false
    exit 1
fi

# 创建密钥对
ssh-keygen -f ~/.ssh/id_rsa -P '' -q
if [ $? -eq 0 ];then
    action "密钥对创建成功！" /bin/true
else
    action "密钥对创建失败！" /bin/false
    exit 1
fi

# 输入远程主机IP地址（可输入多个IP地址）
read -p "请输入需免密登录的主机IP: " HOST_IP

# 输入远程主机root密码
read -p "请输入需要免密登录的主机root密码：" HOST_PASSWORD

# 将公钥文件分发给远程主机
for ip in $HOST_IP
do
    sshpass -p$HOST_PASSWORD ssh-copy-id -f -i ~/.ssh/id_rsa.pub "-o StrictHostKeyChecking=no" root@$ip
    if [ $? -eq 0 ];then
        action "分发公钥文件 id_rsa.pub 至 $ip 成功！" /bin/true
    else
        action "分发公钥文件 id_rsa.pub 至 $ip 失败！" /bin/false
        continue
    fi
done
exit 0
