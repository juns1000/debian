#!/bin/bash
# 采样 10 次，每次间隔 10 秒，算平均值

IFACE=eth0
MAX_BPS=125000000   # 1Gbps

samples=10
interval=10

cpu_sum=0
mem_sum=0
net_sum=0

for ((i=1; i<=samples; i++))
do
    echo "第 $i 次采样..."

    # CPU 使用率 (总平均，不分核心) - 使用 mpstat 更准确
    cpu=$(mpstat 1 1 | awk '/Average/ && $2 ~ /all/ {print 100 - $12}')
    cpu_sum=$(echo "$cpu_sum + $cpu" | bc)

    # 内存使用率
    mem=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100)}')
    mem_sum=$(echo "$mem_sum + $mem" | bc)

    # 磁盘使用率 (/ 根分区)
    disk=$(df -h / | awk 'NR==2 {print $5}')

    # 网络利用率
    rx1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    bps=$(( (rx2 - rx1) + (tx2 - tx1) ))
    net=$(printf "%.2f" "$(echo "$bps*100/$MAX_BPS" | bc -l)")
    net_sum=$(echo "$net_sum + $net" | bc)

    echo "当前值 => CPU: ${cpu}% | MEM: ${mem}% | DISK: $disk | NET: ${net}%"
    sleep $interval
done

cpu_avg=$(echo "scale=2; $cpu_sum / $samples" | bc)
mem_avg=$(echo "scale=2; $mem_sum / $samples" | bc)
net_avg=$(echo "scale=2; $net_sum / $samples" | bc)

echo "========== ${samples} 次采样后的平均值 =========="
echo "CPU Usage: ${cpu_avg}%"
echo "Memory Usage: ${mem_avg}%"
echo "Disk Usage (/): $disk"
echo "Net Usage ($IFACE): ${net_avg}%"
