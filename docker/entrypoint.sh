#!/bin/bash

function exit_vpn() {
    echo "exit vpn"
    /vpnserver/bin/vpnserver stop
    exit 0
}

function usage() {
    echo "Usage: $0 [vpncmd]"
    exit 1
}

# 捕获docker退出的信号，用函数 exit_vpn 优雅退出
trap exit_vpn SIGTERM SIGINT

# 脚本参数个数只能为 0 或 1
if [ $# -gt 1 ]; then
    echo "Usage: $0 [vpncmd]"
    exit 1
fi

# 如果为1个参数，则提取判断参数值是否为 vpncmd
if [ $# -eq 1 ]; then
    if [ "$1" != "vpncmd" ]; then
        usage
    fi

    /vpnserver/bin/vpncmd
else
    # 如果没有参数则执行 vpnserver
    /vpnserver/bin/vpnserver start
fi