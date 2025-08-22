#!/bin/bash

# 定义一个临时文件用于存储已存在的 fstab 条目
TMP_FSTAB="/tmp/fstab_entries.tmp"

# 获取当前 fstab 中已有的 NFS 挂载点（格式：NFS路径 本地目录）
grep -E '\s+nfs\s+' /etc/fstab | awk '{print $1 " " $2}' > "$TMP_FSTAB"

# 定义 NFS 挂载列表，格式：本地挂载点 NFS服务器地址
NFS_MOUNTS=(
	"/nas/store	10.135.193.27:/share-23951675-7e15-4593-accd-d5638a54a951/store"
	"/nas/store_n9000	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meiz_n9000/store_n9000"
	"/nas/store_yf	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meizi_yf/store_yf"
	"/nas/store_sjq	10.135.225.86:/WX-7BK13-MEIZI-SJQ/store_sjq"
	"/nas/store_yqv	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meizi_v/store_yqv"
	"/nas/depository	10.135.193.35:/share-23951675-7e15-4593-accd-d5638a54a951/depository"
	"/nas/depository/asset/zhengshi/1001	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meiz_n9000/depository/asset/zhengshi/1001"
	"/nas/depository/asset/zhengshi/2301	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meiz_n9000/depository/asset/zhengshi/2301"
	"/nas/depository/asset/zhengshi/5101	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meiz_n9000/depository/asset/zhengshi/5101"
	"/nas/depository_yf	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meizi_yf/depository_yf"
	"/nas/depository_sp	10.135.193.81:/share-d951833f-c835-4b07-aefa-8b7c6c76acd7/depository_sp"
	"/nas/depository_sjq	10.135.225.86:/WX-7BK13-MEIZI-SJQ/depository_sjq"
	"/nas/depository_wx	10.135.218.127:/WX-M05-MEIZI/depository_wx"
	"/nas/depository_yqv	10.136.192.68:/share-922de278-a62e-4a46-a6e0-324620b12245/yq_meizi_v/depository_yqv"
	"/nas/opt/swap	10.135.218.29:/WX-M01-MEIZI/n8500"
	"/nas/opt/swap/swap10	10.135.193.35:/share-23951675-7e15-4593-accd-d5638a54a951/swap10"
	"/nas/store_cidcobs_wxlz03	10.135.217.149:/WX-7AE07-MEIZI-HYY1/store_cidcobs_wxlz03"
	"/nas/depository_cidcobs_wxlz03	10.135.217.149:/WX-7AE07-MEIZI-HYY1/depository_cidcobs_wxlz03"
	"/nas/store_nas01	10.138.132.233:/ZQ-06-MEIZI-NAS01/store-nas01"
	"/nas/depository_nas01	10.138.132.233:/ZQ-06-MEIZI-NAS01/depository-nas01"
	"/nas/store_nas02	10.135.225.35:/WX-7BK11-MEIZI-NAS02/store-nas02"
	"/nas/depository_nas02	10.135.225.35:/WX-7BK11-MEIZI-NAS02/depository-nas02"
	"/nas/store_nas03	10.135.218.215:/WX-M08-MEIZI-NAS03/store-nas03"
	"/nas/depository_nas03	10.135.218.215:/WX-M08-MEIZI-NAS03/depository-nas03"
	"/nas/store_nas04	10.135.217.149:/WX-7AE07-MEIZI-NAS04/store-nas04"
	"/nas/depository_nas04	10.135.217.149:/WX-7AE07-MEIZI-NAS04/depository-nas04"
	"/nas/store-nas05	10.138.132.74:/ZQ-18-MEIZI-NAS05/store-nas05"
	"/nas/depository-nas05	10.138.132.74:/ZQ-18-MEIZI-NAS05/depository-nas05"
	"/nas/store-nas06	10.136.192.68:/YQ-PI01-MEIZI-NAS06/store-nas06"
	"/nas/depository-nas06	10.136.192.68:/YQ-PI01-MEIZI-NAS06/depository-nas06"
	"/nas/store-nas07	10.138.135.44:/ZQ-1414-MEIZI-NAS07/store-nas07"
	"/nas/depository-nas07	10.138.135.44:/ZQ-1414-MEIZI-NAS07/depository-nas07"
	"/nas/store-nas08	10.135.193.33:/WX-6BL14-MEIZI-NAS08/store-nas08"
	"/nas/depository-nas08	10.135.193.33:/WX-6BL14-MEIZI-NAS08/depository-nas08"
	# ... 省略其他条目 ...
)

# 遍历挂载列表
for MOUNT_INFO in "${NFS_MOUNTS[@]}"; do
    LOCAL_DIR=$(echo "$MOUNT_INFO" | awk '{print $1}')
    NFS_PATH=$(echo "$MOUNT_INFO" | awk '{print $2}')
    
    echo "处理挂载点: $LOCAL_DIR -> $NFS_PATH"

    # 创建本地目录（如果不存在）
    if [ ! -d "$LOCAL_DIR" ]; then
        echo "创建目录: $LOCAL_DIR"
        sudo mkdir -p "$LOCAL_DIR"
    fi

    # 检查是否已经挂载
    if mountpoint -q "$LOCAL_DIR"; then
        echo "$LOCAL_DIR 已挂载，跳过。"
        continue
    fi

    # 挂载 NFS（指定版本）
    echo "正在挂载: $NFS_PATH 到 $LOCAL_DIR"
    sudo mount -t nfs -o vers=3 "$NFS_PATH" "$LOCAL_DIR"
    if [ $? -eq 0 ]; then
        echo "挂载成功。"
    else
        echo "挂载失败，请检查网络或NFS服务器状态。"
        continue
    fi

    # 检查 fstab 是否已有该条目
    if grep -q "^$NFS_PATH $LOCAL_DIR" "$TMP_FSTAB"; then
        echo "/etc/fstab 中已存在该挂载条目，跳过写入。"
        continue
    fi

    # 写入 /etc/fstab
    echo "将挂载信息写入 /etc/fstab"
    echo "$NFS_PATH $LOCAL_DIR nfs defaults,_netdev,nofail 0 0" | sudo tee -a /etc/fstab > /dev/null
done

# 清理临时文件
rm -f "$TMP_FSTAB"

echo "所有 NFS 挂载操作完成。"
