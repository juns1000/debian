#!/bin/bash

IFACE=eth0
MAX_BPS=125000000  # 1Gbps

cpu_sum=0
mem_sum=0
net_sum=0
count=0

while [ $count -lt 30 ]; do   # 30次 * 10秒 = 5分钟
    # CPU 使用率
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    
    # MEM 使用率
    mem=$(free | awk '/Mem/ {print $3/$2 * 100}')
    
    # NET 使用率
    rx1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    bps=$(( (rx2 - rx1) + (tx2 - tx1) ))
    net=$(echo "$bps*100/$MAX_BPS" | bc -l)

    # 累加
    cpu_sum=$(echo "$cpu_sum + $cpu" | bc)
    mem_sum=$(echo "$mem_sum + $mem" | bc)
    net_sum=$(echo "$net_sum + $net" | bc)

    count=$((count + 1))
    sleep 9   # 前面已经 sleep 1s 测网速 + 这里再 sleep 9s = 总共 10秒
done

cpu_avg=$(echo "scale=2; $cpu_sum/$count" | bc)
mem_avg=$(echo "scale=2; $mem_sum/$count" | bc)
net_avg=$(echo "scale=2; $net_sum/$count" | bc)

disk=$(df -h | awk '$6=="/" {print $5}')

echo "========== 5分钟平均值 (10秒采样一次) =========="
echo "CPU Usage: ${cpu_avg}%"
echo "Memory Usage: ${mem_avg}%"
echo "Disk Usage (/): $disk"
echo "Net Usage ($IFACE): ${net_avg}%"
