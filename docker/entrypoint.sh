#!/bin/bash

#################################### global variable

g_bin=
g_start_cmd=
g_exit_cmd=

#################################### function

function exit_vpn() {
    echo "exit vpn"

    $g_exit_cmd

    exit 0
}

function usage() {
    echo "Usage: $0 <COMMAND>
    COMMAND:
        vpncmd    : run vpncmd
        vpnserver : run vpnserver
        vpnbridge : run vpnbridge"

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
    if [ "$1" == "vpncmd" ]; then
        g_bin=/vpn/bin/vpncmd
        g_start_cmd=$g_bin
        g_exit_cmd=$g_bin
    elif [ "$1" == "vpnserver" ]; then
        g_bin=/vpn/bin/vpnserver
        g_start_cmd="$g_bin start"
        g_exit_cmd="$g_bin stop"
    elif [ "$1" == "vpnbridge" ]; then
        g_bin=/vpn/bin/vpnbridge
        g_start_cmd="$g_bin start"
        g_exit_cmd="$g_bin stop"
    elif [ "$1" == "vpnclient" ]; then
        g_bin=/vpn/bin/vpnclient
        g_start_cmd="$g_bin start"
        g_exit_cmd="$g_bin stop"
    else
        usage
    fi

    $g_start_cmd
else
    usage
fi