#!/bin/bash
# CPU
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
# MEM
MEM=$(free | awk '/Mem/ {printf("%.1f%%", $3/$2 * 100)}')
# DISK
DISK=$(df -h | awk '$6=="/data" {print $5}')
# NET
IFACE=eth0
MAX_BPS=125000000
rx1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
tx1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
rx2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
tx2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
bps=$(( (rx2 - rx1) + (tx2 - tx1) ))
NET=$(printf "%.2f%%" "$(echo "$bps*100/$MAX_BPS" | bc -l)")

echo "CPU Usage: $CPU"
echo "Memory Usage: $MEM"
echo "Disk Usage: $DISK"
echo "Net Usage($IFACE): $NET"
