#!/bin/bash

# 变量定义
WORK_DIR=$(cd $(dirname $0);pwd)
USER=$(whoami)


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


# 输入需要创建的python环境版本
read -p "请输入需要安装的python3版本：" PYTHON_VERSION
#echo $PYTHON_VERSION
if [[ "$PYTHON_VERSION" != python3* ]];then
	echo $PYTHON_VERSION
	echo "请输入正确的python版本！"
	exit 2
fi

#######################################  （1）安装Anaconda  ############################################
# 下载Anaconda
if [[ ! -f $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh ]];then
	curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://mirrors.aliyun.com/anaconda/archive/Anaconda3-2021.04-Linux-x86_64.sh
	# curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://gitee.com/wangjiazhu/packages/raw/main/Anaconda3-2021.04-Linux-x86_64.sh
	# curl -o $WORK_DIR/Anaconda3-2020.11-Linux-x86_64.sh https://raw.githubusercontent.com/wangjiazhu/packages/main/Anaconda3-2021.04-Linux-x86_64.sh
	if [[ $? != 0 ]];then
		echo "Anaconda下载失败！"
		exit 3
	else
		echo "Anaconda下载成功！"
	fi
else
	echo "Anaconda已存在！"
fi

expect <<EOF
set timeout -1
spawn sh ${WORK_DIR}/Anaconda3-2020.11-Linux-x86_64.sh
expect ">>> "
send "\r"
send "q"
expect "\[no\] >>>"
send "yes\r"
expect "\[/root/anaconda3\]"
send "/application/anaconda3\r"
expect "\[no\]"
send "yes\r"
expect eof
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
# 加载conda环境变量
source ~/.bashrc

# 创建Python虚拟环境

expect <<EOF
set timeout -1
spawn conda create --name ${PYTHON_VERSION} python=${PYTHON_VERSION}
expect "Proceed"
send "y\r"
expect eof
EOF

# 创建成功后，将激活虚拟环境添加到开机自启
chmod +x /etc/rc.d/rc.local
RET_VAL2=$(cat /etc/rc.local |grep "conda activate $PYTHON_VERSION"|wc -l)
if [ $RET_VAL2 -eq 0 ];then
	echo "conda activate $PYTHON_VERSION" >>/etc/rc.d/rc.local
fi
RET_VAL3=$(cat ~/.bashrc |grep "conda activate $PYTHON_VERSION" |wc -l)
if [ $RET_VAL3 -eq 0 ];then
	echo "conda activate $PYTHON_VERSION" >>~/.bashrc
fi

# 重启机器
reboot
########################################################################################################

# 激活虚拟环境
#conda activate $PYTHON_VERSION