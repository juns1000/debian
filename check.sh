#!/bin/bash
# 使用方法:
#   ./monitor.sh --duration 300 --interval 10

IFACE=eth0
MAX_BPS=125000000   # 1Gbps

# 默认参数
DURATION=300
INTERVAL=10

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration)
      DURATION="$2"
      shift 2
      ;;
    --interval)
      INTERVAL="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

# 计算采样次数
SAMPLES=$(( DURATION / INTERVAL ))

cpu_sum=0
mem_sum=0
net_sum=0

get_cpu_usage() {
    # 第一次读取 CPU 时间
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < <(grep '^cpu ' /proc/stat)
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle1=$((idle + iowait))
    
    sleep 1
    
    # 第二次读取 CPU 时间
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < <(grep '^cpu ' /proc/stat)
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle2=$((idle + iowait))
    
    # 计算 CPU 使用率
    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))
    cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
    echo "$cpu_usage"
}

for ((i=1; i<=SAMPLES; i++))
do
    echo "第 $i/$SAMPLES 次采样..."

    # CPU 使用率
    cpu=$(get_cpu_usage)
    cpu_sum=$((cpu_sum + cpu))

    # 内存使用率
    mem=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100)}')
    mem_sum=$(echo "$mem_sum + $mem" | bc)

    # 磁盘使用率
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
    sleep $((INTERVAL - 1))
done

# 计算平均值
cpu_avg=$(echo "scale=2; $cpu_sum / $SAMPLES" | bc)
mem_avg=$(echo "scale=2; $mem_sum / $SAMPLES" | bc)
net_avg=$(echo "scale=2; $net_sum / $SAMPLES" | bc)

echo "========== 平均值 =========="
echo "CPU Usage: ${cpu_avg}%"
echo "Memory Usage: ${mem_avg}%"
echo "Disk Usage: $disk"
echo "Net Usage: ${net_avg}%"
