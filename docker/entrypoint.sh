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

#################################### main

# 捕获docker退出的信号，用函数 exit_vpn 优雅退出
trap exit_vpn SIGTERM SIGINT

# 脚本参数个数只能为 0 或 1
if [ $# -gt 1 ]; then
    echo "too many arguments: $*"
    usage
    exit 1
fi

conf_cmd=$1

if [ -z "$conf_cmd" ]; then
    conf_cmd=$VPN_CMD
fi

if [ "$conf_cmd" == "vpncmd" ]; then
    g_bin=/vpn/bin/vpncmd
    g_start_cmd=$g_bin
    g_exit_cmd=$g_bin
elif [ "$conf_cmd" == "vpnserver" ]; then
    g_bin=/vpn/bin/vpnserver
    g_start_cmd="$g_bin execsvc"
    g_exit_cmd="$g_bin stop"
elif [ "$conf_cmd" == "vpnbridge" ]; then
    g_bin=/vpn/bin/vpnbridge
    g_start_cmd="$g_bin execsvc"
    g_exit_cmd="$g_bin stop"
elif [ "$conf_cmd" == "vpnclient" ]; then
    g_bin=/vpn/bin/vpnclient
    g_start_cmd="$g_bin execsvc"
    g_exit_cmd="$g_bin stop"
else
    echo "invalid argument: $conf_cmd"
    usage
fi

$g_start_cmd