#!/bin/bash

# Author: wjz
# Email : 1072002783@qq.com
# Blog  : https://blog.csdn.net/weixin_51720652
# Func  : 部署NFS服务端或客户端

source /etc/init.d/functions

# 服务端
function nfsServer() {
	# 终端获取nfs服务器IP
	read -p $'-----------------------------\n请输入NFS服务器IP地址...\nNFS服务端IP >>> ' NFS_SERVER_IP
	
	# 判断IP地址合法性
	RET1=$(echo "$(ip addr|grep -w inet|awk '{print $2}'|awk -F/ '{print $1}')"|grep $NFS_SERVER_IP|wc -l)
	if [ $RET1 -ne 1 ];then
		echo "$NFS_SERVER_IP非本机IP地址，请检查！"
		exit 1
	fi
	
	# 安装NFS服务端必要组件
	yum install nfs-utils rpcbind -y
	
	# 安装成功，启动服务
	systemctl start rpcbind
	systemctl enable rpcbind
	systemctl start nfs
	systemctl enable nfs
	
	# 终端获取nfs共享目录
	read -p $'-----------------------------\n请设置NFS服务器共享目录(回车共享目录默认为/data)...\nNFS共享目录 >>> ' NFS_SERVER_DIR
	# echo $NFS_SERVER_DIR
	if [[ $NFS_SERVER_DIR == "" ]];then
		NFS_SERVER_DIR="/data"
		mkdir -p $NFS_SERVER_DIR
	else
		mkdir -p $NFS_SERVER_DIR
	fi
	
	# 指定共享IP地址范围
	read -p $'-----------------------------\n请设置NFS服务器允许挂载的IP地址或网络段...\n示例  IP: 192.168.1.11 网络段：192.168.1.0/24\n(IP/网络段) >>> ' IP_RANGE
	
	
	# 是否指定指定用户和用户组的用户访问共享目录
	read -p $'-----------------------------\n是否限制客户端指定用户名访问？(yes/no)默认no...\n(yes/no) >>> ' LIMIT_USER_FLAG
	if [[ $LIMIT_USER_FLAG != "yes" ]];then
		echo "$NFS_SERVER_DIR $IP_RANGE(rw,sync,no_root_squash)" >/etc/exports
	else
		# 创建用户和用户组
		read -p $'请指定用户组名称和用户组ID(默认值为：nfs 1111)...\n(GNAME GID) >>> ' GROUP_NAME_ID
		if [[ $GROUP_NAME_ID == "" ]];then
			GROUP_NAME_ID="nfs 1111"
		fi
		GROUP_NAME_ID=($GROUP_NAME_ID)
		# echo ${GROUP_NAME_ID[1]}
		groupadd -g ${GROUP_NAME_ID[1]} ${GROUP_NAME_ID[0]}
		useradd ${GROUP_NAME_ID[0]} -u ${GROUP_NAME_ID[1]} -g ${GROUP_NAME_ID[1]} -s /sbin/nologin -M
		chown -R ${GROUP_NAME_ID[0]}:${GROUP_NAME_ID[0]} $NFS_SERVER_DIR
		
		# 配置共享目录配置文件
		echo "$NFS_SERVER_DIR $IP_RANGE(rw,sync,all_squash,anonuid=${GROUP_NAME_ID[1]},anongid=${GROUP_NAME_ID[1]})" >/etc/exports
		# echo "$NFS_SERVER_DIR $IP_RANGE(rw,sync,all_squash,anonuid=${GROUP_NAME_ID[1]},anongid=${GROUP_NAME_ID[1]})"
	fi
	
	# 重启服务
	systemctl restart rpcbind
	systemctl restart nfs
}


# 客户端
function nfsClient(){
	# 终端获取nfs服务器IP
	read -p $'-----------------------------\n请输入NFS服务器IP地址...\nNFS服务端IP >>> ' NFS_SERVER_IP
	# 安装客户端软件
	yum install nfs-utils -y
	
	# 检查NFS服务端挂载目录
	showmount -e $NFS_SERVER_IP
	if [ $? -ne 0 ];then
		action "服务端：$NFS_SERVER_IP共享目录失败" /bin/false
		echo "检查$NFS_SERVER_IP地址是否正确、本机IP是否与$NFS_SERVER_IP同网段等"
		exit 1
	fi
	
	# 判断是否需要特定用户共享
	read -p $'-----------------------------\n是否限制客户端指定用户名访问？(yes/no)默认no...\n(yes/no) >>> ' LIMIT_USER_FLAG
	if [[ $LIMIT_USER_FLAG == "yes" ]];then
		# 创建用户和用户组
		read -p $'请指定用户组名称和用户组ID(默认值为：nfs 1111)...\n(GNAME GID) >>> ' GROUP_NAME_ID
		if [[ $GROUP_NAME_ID == "" ]];then
			GROUP_NAME_ID="nfs 1111"
		fi
		GROUP_NAME_ID=($GROUP_NAME_ID)
		# echo ${GROUP_NAME_ID[1]}
		groupadd -g ${GROUP_NAME_ID[1]} ${GROUP_NAME_ID[0]}
		useradd ${GROUP_NAME_ID[0]} -u ${GROUP_NAME_ID[1]} -g ${GROUP_NAME_ID[1]} -s /sbin/nologin -M
	fi
	
	# 挂载
	read -p $'-----------------------------\n是否挂载NFS共享目录？(yes/no)默认no...\n(yes/no) >>> ' MOUNT_FLAG
	if [[ $MOUNT_FLAG != "yes" ]];then
		exit 0
	fi
	
	read -p $'-----------------------------\n请设置挂载目录(默认挂载目录为/data)...\n挂载目录 >>> ' MOUNT_DIR
	if [[ $MOUNT_DIR == "" ]];then
		MOUNT_DIR="/data"
	fi
	if [ ! -d "$MOUNT_DIR" ];then
		mkdir -p $MOUNT_DIR
	fi
	NFS_SERVER_DIR=$(showmount -e $NFS_SERVER_IP|awk 'NR==2{print $1}')
	mount -t nfs $NFS_SERVER_IP:$NFS_SERVER_DIR $MOUNT_DIR
	if [ $? -ne 0 ];then
		action "挂载$NFS_SERVER_IP:$NFS_SERVER_DIR至$MOUNT_DIR" /bin/false
		exit 1
	else
		action "挂载$NFS_SERVER_IP:$NFS_SERVER_DIR至$MOUNT_DIR" /bin/true
	fi
	read -p $'-----------------------------\n是否开机挂载NFS共享目录？(yes/no)默认no...\n(yes/no) >>> ' ALL_MOUNT_FLAG
	if [[ $ALL_MOUNT_FLAG == "yes" ]];then
		echo "mount -t nfs $NFS_SERVER_IP:$NFS_SERVER_DIR $MOUNT_DIR" >>/etc/bashrc
	fi
}



function main() {
cat <<EOF
---------------请选择部署方案---------------
                0 NFS服务端                 
                1 NFS客户端                 
--------------------------------------------
EOF
read -p $'请选择部署方案序号(0/1)...\n(0/1) >>> ' DEPLOY_FLAG
if [ $DEPLOY_FLAG -eq 0 ];then
	nfsServer
	if [ $? -ne 0 ];then
		action "服务端：$NFS_SERVER_IP部署NFS服务" /bin/false
	else
		action "服务端：$NFS_SERVER_IP部署NFS服务" /bin/true
	fi
else
	nfsClient
	if [ $? -ne 0 ];then
		action "客户端部署NFS服务" /bin/false
	else
		action "客户端部署NFS服务" /bin/true
	fi
fi
}
main