#!/bin/bash

# 快速修复Livox雷达IP配置脚本
# 自动检测雷达实际IP并更新配置文件

CONFIG_FILE="/home/bingda/ws_livox/src/livox_ros_driver2/config/MID360_config.json"

echo "=========================================="
echo "Livox雷达IP快速修复工具"
echo "=========================================="

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 查找Livox设备（MAC地址前缀 0c:9a）
echo "正在查找Livox雷达..."
LIVOX_IP=$(arp -a | grep -E "0c:9a|00:16|00:1e" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)

if [ -z "$LIVOX_IP" ]; then
    echo "未找到Livox设备，尝试扫描网络..."
    # 快速扫描192.168.1.x网段
    for i in {150..200}; do
        ip="192.168.1.$i"
        if timeout 0.1 ping -c 1 -W 1 "$ip" &> /dev/null; then
            mac=$(arp -a | grep "$ip" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}' | head -1)
            if echo "$mac" | grep -qE "^0c:9a|^00:16|^00:1e"; then
                LIVOX_IP="$ip"
                break
            fi
        fi
    done
fi

if [ -z "$LIVOX_IP" ]; then
    echo "错误: 未找到Livox雷达设备"
    echo "请确保："
    echo "1. 雷达已上电并连接到网络"
    echo "2. 雷达和主机在同一网段（192.168.1.x）"
    exit 1
fi

echo "找到Livox雷达IP: $LIVOX_IP"

# 备份原配置文件
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
echo "已备份原配置文件"

# 更新配置文件中的IP地址
sed -i "s/\"lidar_ip\"\\s*:\\s*\\[\"[^\"]*\"\\]/\"lidar_ip\": [\"$LIVOX_IP\"]/g" "$CONFIG_FILE"
sed -i "s/\"ip\"\\s*:\\s*\"[^\"]*\"/\"ip\": \"$LIVOX_IP\"/g" "$CONFIG_FILE"

echo "配置文件已更新"
echo ""
echo "更新内容："
echo "  雷达IP: $LIVOX_IP"
echo ""
echo "下一步："
echo "1. 重新启动驱动："
echo "   ros2 launch livox_ros_driver2 msg_MID360_launch.py"
echo ""
echo "2. 等待30-60秒后检查话题："
echo "   ros2 topic list | grep livox"
echo ""

