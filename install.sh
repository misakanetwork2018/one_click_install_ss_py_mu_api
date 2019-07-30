#!/bin/sh

GETOPT_ARGS=`getopt -o sp:u:n:ra -l supervisor,pass:,url:,node:,run,autorestart -- "$@"`
eval set -- "$GETOPT_ARGS"
OLD_IFS="$IFS"
IFS=" "
arguments=($*)
IFS="$OLD_IFS"
supervisor=false
pass=""
url=""
node=""
autorestart=false
run=false

#获取参数
while [ -n "$1" ]
do
	case "$1" in
		-s|--supervisor) supervisor=true;shift 1;;
		-r|--run) run=true;shift 1;;
		-a|--autorestart) autorestart=true;shift 1;;
                -p|--pass) pass=$2;shift 2;;
                -h|--host) host=$2;shift 2;;
                -u|--url) url=$2;shift 2;;
                -n|--node) node=$2;shift 2;;
                --) break ;;
                *) break ;;
        esac
done

#获得系统类型
Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

#安装依赖
function instdpec()
{
	if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
		$PM -y install wget
		$PM -y install 
		TEST=`git --version`
		if  [ ! -n "$TEST" ] ;then
		$PM -y install git
		fi
		$PM -y groupinstall "Development Tools"
		$PM -y update nss curl
	elif [ "$1" == "Debian" ] || [ "$1" == "Raspbian" ] || [ "$1" == "Ubuntu" ];then
		$PM update
		$PM -y install wget
		TEST=`git --version`
		if  [ ! -n "$TEST" ] ;then
		$PM -y install git
		fi
		$PM -y install build-essential
	else
		echo "The shell can be just supported to install ssr on Centos, Ubuntu and Debian."
		exit 1
	fi
}

Get_Dist_Name

echo "Your OS is $DISTRO"

echo -e "\033[42;34mInstall dependent packages\033[0m"
instdpec $DISTRO;

cd /root
if [ ! -f "/etc/ld.so.conf.d/usr_local_lib.conf" ]; then
wget https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz
if [ ! -f "./libsodium-1.0.17.tar.gz" ]; then
echo "Download fail. Please try again."
exit 1;
fi
tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
cd /root
rm -rf libsodium-1.0.17.tar.gz
rm -rf libsodium-1.0.17
fi

git clone -b manyuser https://github.com/misakanetwork2018/shadowsocks-py-mu.git shadowsocks
if [ ! -d "./shadowsocks" ]; then
echo "Download fail. Please try again."
exit 1;
fi

cp /root/shadowsocks/shadowsocks/config_example.py /root/shadowsocks/shadowsocks/config.py

if $supervisor; then
echo "Installing supervisor..."
cd /usr/local/src
if !  command -v easy_install > /dev/null; then
	wget https://bootstrap.pypa.io/ez_setup.py
	if [ ! -f "./ez_setup.py" ]; then
	echo "Download fail. Please try again."
	exit 1;
	fi
	python ez_setup.py
	if !  command -v easy_install > /dev/null; then
		echo "Install fail. Please try again."
		exit 1;
	fi
fi
if !  command -v /usr/bin/supervisorctl > /dev/null; then
wget -c https://pypi.python.org/packages/7b/17/88adf8cb25f80e2bc0d18e094fcd7ab300632ea00b601cbbbb84c2419eae/supervisor-3.3.2.tar.gz
if [ ! -f "./supervisor-3.3.2.tar.gz" ]; then
echo "Download fail. Please try again."
exit 1;
fi
tar -zxvf supervisor-3.3.2.tar.gz
cd supervisor-3.3.2
/usr/bin/supervisorctl stop all
python setup.py install
if !  command -v /usr/bin/supervisorctl > /dev/null; then
echo "Install fail. Please try again."
exit 1;
fi
fi
echo_supervisord_conf > /etc/supervisord.conf
cat >> /etc/supervisord.conf  << EOF
[include]
files=/etc/supervisor/*.conf #若你本地无/etc/supervisor目录，请自建
EOF
mkdir -p /etc/supervisor
mkdir -p /var/log/supervisord
rm -rf /etc/supervisor/ss.conf
cat > /etc/supervisor/ss.conf <<EOF
; 设置进程的名称，使用 supervisorctl 来管理进程时需要使用该进程名
[program:shadowsocks]
command=python servers.py
;numprocs=1 ; 默认为1 
;process_name=%(program_name)s ; 默认为 %(program_name)s，即 [program:x] 中的 x 
directory=/root/shadowsocks/shadowsocks ; 执行 command 之前，先切换到工作目录
user=root ; 使用 root 用户来启动该进程
; 程序崩溃时自动重启，重启次数是有限制的，默认为3次 autorestart=true 
redirect_stderr=true
; 重定向输出的日志
stdout_logfile = /var/log/supervisord/ss_server.log
loglevel=info
EOF
fi

sed -i "s/API_ENABLED = False/API_ENABLED = True/" /root/shadowsocks/shadowsocks/config.py

if [[ -n "$url" ]]; then
sed -i "s#API_URL = 'http://domain/mu'#API_URL = '$url'#" /root/shadowsocks/shadowsocks/config.py
fi
if [[ -n "$pass" ]]; then
sed -i "s/API_PASS = 'mupass'/API_PASS = '$pass'/" /root/shadowsocks/shadowsocks/config.py
fi
if [[ -n "$node" ]]; then
sed -i "s/API_NODE_ID = '1'/API_NODE_ID = '$node'/" /root/shadowsocks/shadowsocks/config.py
fi

if $run; then
supervisord -c /etc/supervisord.conf
supervisorctl reload
fi

if $autorestart; then
sed -i 's/0 4 * * * supervisorctl reload//' /var/spool/cron/root
echo "0 4 * * * supervisorctl reload" >> /var/spool/cron/root
	if [ "$DISTRO" == "CentOS" ] || [ "$DISTRO" == "CentOS7" ];then
		echo "supervisord" >> /etc/rc.local
		if [ "$DISTRO" == "CentOS7" ]; then
		chmod +x /etc/rc.local
		fi
	elif [ "$DISTRO" == "Debian" ] || [ "$DISTRO" == "Raspbian" ] || [ "$DISTRO" == "Ubuntu" ];then
		sed -i 's/exit 0/supervisord\nexit 0/' /etc/rc.local
	fi
fi

echo "Install completely."
