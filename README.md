# one_click_install_ss_py_mu_api

该脚本会把ss mu安装到/root中，请在root权限下安装，否则会安装失败

该版本ss要求使用Python2.7及更高版本，不完全支持Python2.6

目前已知能够正常运行在Centos7 x64中，其他系统请自行测试

一键命令：wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/one_click_install_ss_py_mu_api/master/install.sh && sh install.sh

本脚本可接收以下参数，以便全自动部署：  
-s|--supervisor  安装后台守护程序  
-r|--run 安装完毕后立刻运行守护程序  
-n|--node 修改config.py中的API_NODE_ID 
-p|--pass 修改config.py中的API_PASS
-u|--url 修改config.py中的API_URL
