#!/bin/bash
# 混合监控脚本：历史 + 实时
# 依赖：sysstat（提供 sar）

IFACE=eth0
MAX_BPS=125000000   # 1Gbps = 125MB/s

# ========== 历史部分 ==========
echo "========== 过去24小时平均值 (sar 数据) =========="

# CPU 历史平均
cpu_hist=$(LC_ALL=C sar -u -f /var/log/sysstat/sa$(date +%d) | awk '/Average/ {print 100 - $8}')
echo "CPU Usage (avg): ${cpu_hist}%"

# 内存历史平均
mem_hist=$(LC_ALL=C sar -r -f /var/log/sysstat/sa$(date +%d) | awk '/Average/ {printf("%.2f", $4/($2+$3+$4)*100)}')
echo "Memory Usage (avg): ${mem_hist}%"

# 网络历史平均 (只取 eth0)
net_hist=$(LC_ALL=C sar -n DEV -f /var/log/sysstat/sa$(date +%d) | awk -v iface=$IFACE '
/Average/ && $2==iface {printf("%.2f", ($5+$6)*100/125000000)}')
echo "Net Usage ($IFACE avg): ${net_hist}%"

# 磁盘（实时看，sar 的 -d 统计不一定包含 /）
disk_usage=$(df -h / | awk 'NR==2 {print $5}')
echo "Disk Usage (/): $disk_usage"

# ========== 实时部分 ==========
echo ""
echo "========== 实时采样 (5分钟, 每10秒一次) =========="

DURATION=300
INTERVAL=10
SAMPLES=$(( DURATION / INTERVAL ))

cpu_sum=0
mem_sum=0
net_sum=0

for ((i=1; i<=SAMPLES; i++))
do
    echo "采样 $i/$SAMPLES ..."

    # CPU 使用率
    cpu=$(mpstat 1 1 | awk '/Average/ && $2 ~ /all/ {print 100 - $12}')
    cpu_sum=$(echo "$cpu_sum + $cpu" | bc)

    # 内存使用率
    mem=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100)}')
    mem_sum=$(echo "$mem_sum + $mem" | bc)

    # 网络利用率
    rx1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    sleep 1
    rx2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    bps=$(( (rx2 - rx1) + (tx2 - tx1) ))
    net=$(printf "%.2f" "$(echo "$bps*100/$MAX_BPS" | bc -l)")
    net_sum=$(echo "$net_sum + $net" | bc)

    echo "当前值 => CPU: ${cpu}% | MEM: ${mem}% | DISK: $disk_usage | NET: ${net}%"
    sleep $((INTERVAL - 1))
done

cpu_avg=$(echo "scale=2; $cpu_sum / $SAMPLES" | bc)
mem_avg=$(echo "scale=2; $mem_sum / $SAMPLES" | bc)
net_avg=$(echo "scale=2; $net_sum / $SAMPLES" | bc)

echo ""
echo "========== 实时 5分钟平均值 =========="
echo "CPU Usage: ${cpu_avg}%"
echo "Memory Usage: ${mem_avg}%"
echo "Disk Usage (/): $disk_usage"
echo "Net Usage ($IFACE): ${net_avg}%"
