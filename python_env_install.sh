#!/bin/bash

# 变量定义
WORK_DIR=$(cd $(dirname $0);pwd)
USER=$(whoami)
PYTHON="python"


# 判断当前是否是root用户
if [[ $USER != "root" ]];then
	echo "${USER} 不是root用户！"
	exit 1
fi

# 判断当前环境是否支持expect脚本
RET_VAL1=$(rpm -aq expect|wc -l)
if [ $RET_VAL1 -lt 1 ];then
	yum install expect -y
fi

#######################################  （1）安装Anaconda  ############################################
# 下载Anaconda
if [[ ! -f $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh ]];then
	curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://mirrors.aliyun.com/anaconda/archive/Anaconda3-2021.04-Linux-x86_64.sh
	# curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://gitee.com/wangjiazhu/packages/raw/main/Anaconda3-2021.04-Linux-x86_64.sh
	# curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://raw.githubusercontent.com/wangjiazhu/packages/main/Anaconda3-2021.04-Linux-x86_64.sh
	if [[ $? != 0 ]];then
		echo "Anaconda下载失败！"
		exit 1
	else
		echo "Anaconda下载成功！"
	fi
else
	echo "Anaconda已存在！"
fi

expect <<EOF
set timeout -1
spawn sh ${WORK_DIR}/Anaconda3-2020.11-Linux-x86_64.sh
expect ">>> " {send "\n"}
send "q"
expect {
	"Do you accept the license terms" {send "yes\n";exp_continue}
	"Anaconda3 will now be installed into this location" {send "/application/anaconda3\n";exp_continue}
	"by running conda init" {send "yes\n";exp_continue}
}
EOF

# 加载conda环境变量
source ~/.bashrc

# 添加 Anaconda Python 免费仓库
cat >~/.condarc <<EOF
channels:
  - defaults
show_channel_urls: true
default_channels:
  - http://mirrors.aliyun.com/anaconda/pkgs/main
  - http://mirrors.aliyun.com/anaconda/pkgs/r
  - http://mirrors.aliyun.com/anaconda/pkgs/msys2
custom_channels:
  conda-forge: http://mirrors.aliyun.com/anaconda/cloud
  msys2: http://mirrors.aliyun.com/anaconda/cloud
  bioconda: http://mirrors.aliyun.com/anaconda/cloud
  menpo: http://mirrors.aliyun.com/anaconda/cloud
  pytorch: http://mirrors.aliyun.com/anaconda/cloud
  simpleitk: http://mirrors.aliyun.com/anaconda/cloud
EOF

# 搜索时显示通道信息
conda config --set show_channel_urls yes

# 清除索引缓存
conda clean -i

########################################################################################################




####################################  （2）创建Python虚拟环境  #########################################
# 判断用户是否需要创建python虚拟环境
read -p $'是否创建虚拟环境(yes/no)？\n[yes/no] >>> ' PYTHON_INSTALL
if [[ "$PYTHON_INSTALL" != "yes" ]];then
	exit 1
fi

# 若创建，判断用户需要的python版本
read -p $'请输入python3版本(3.6.x/3.7.x/3.8.x)[可省略次版本x]\npython版本 >>> ' PYTHON_VERSION
if [[ "${PYTHON}${PYTHON_VERSION}" != python3* ]];then
	echo $PYTHON_VERSION
	echo "请输入正确的python版本！"
	exit 1
fi

# 加载conda环境变量并创建python虚拟环境
source ~/.bashrc

expect <<EOF
set timeout -1
spawn conda create --name ${PYTHON}${PYTHON_VERSION} python=${PYTHON_VERSION}
expect {
	"Proceed" {send "y\n";exp_continue}
}
EOF

sleep 3

# 创建成功后，将激活虚拟环境添加到开机自启
chmod +x /etc/rc.d/rc.local
RET_VAL2=$(cat /etc/rc.local |grep "conda activate ${PYTHON}${PYTHON_VERSION}"|wc -l)
if [ $RET_VAL2 -eq 0 ];then
	echo "conda activate ${PYTHON}${PYTHON_VERSION}" >>/etc/rc.d/rc.local
fi
RET_VAL3=$(cat ~/.bashrc |grep "conda activate ${PYTHON}${PYTHON_VERSION}" |wc -l)
if [ $RET_VAL3 -eq 0 ];then
	echo "conda activate ${PYTHON}${PYTHON_VERSION}" >>~/.bashrc
fi

# 重启机器
reboot
########################################################################################################