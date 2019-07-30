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

if [[ -n "$url" ]]; then
sed -i "s/API_URL = 'http://domain/mu'/API_URL = '$url'/" config.py
fi
