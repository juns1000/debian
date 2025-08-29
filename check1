#!/bin/bash

# 需要安装 sysstat (提供 sar)
# CentOS/RHEL: yum install -y sysstat
# Ubuntu/Debian: apt-get install -y sysstat

# CPU 平均
CPU=$(sar -u -s 00:00:00 -e 23:59:59 | awk '/Average/ {print 100 - $8"%"}')

# MEM 平均 (kbmemused / kbmemfree)
MEM=$(sar -r -s 00:00:00 -e 23:59:59 | awk '/Average/ {printf("%.1f%%", $4/$2*100)}')

# DISK 使用率平均 (以 / 为例)
DISK=$(df -h | awk '$6=="/" {print $5}')

# NET 平均吞吐 (以 eth0 为例)
IFACE=eth0
# sar -n DEV 输出 KB/s
NET=$(sar -n DEV -s 00:00:00 -e 23:59:59 | awk -v IFACE="$IFACE" '$2==IFACE && /Average/ {rx=$5; tx=$6; print (rx+tx)" KB/s"}')

echo "========== 一天平均值 =========="
echo "CPU Usage: $CPU"
echo "Memory Usage: $MEM"
echo "Disk Usage (/): $DISK"
echo "Net Usage ($IFACE): $NET"
