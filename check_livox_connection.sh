#!/bin/bash

echo "=========================================="
echo "Livox雷达连接诊断工具"
echo "=========================================="

# 检查节点是否运行
echo -e "\n[1] 检查节点状态"
echo "----------------------------------------"
if pgrep -f livox_ros_driver2_node > /dev/null; then
    echo "✓ livox_ros_driver2_node 正在运行"
    PID=$(pgrep -f livox_ros_driver2_node | head -1)
    echo "  进程ID: $PID"
else
    echo "✗ livox_ros_driver2_node 未运行"
fi

# 检查话题
echo -e "\n[2] 检查话题"
echo "----------------------------------------"
TOPICS=$(ros2 topic list 2>/dev/null | grep livox)
if [ -z "$TOPICS" ]; then
    echo "✗ 未找到livox相关话题"
    echo "  这表示雷达还没有开始发送数据"
else
    echo "✓ 找到以下话题:"
    echo "$TOPICS" | sed 's/^/  /'
fi

# 检查网络连接
echo -e "\n[3] 检查网络连接"
echo "----------------------------------------"
LIDAR_IP="192.168.1.175"
if ping -c 2 -W 1 "$LIDAR_IP" &> /dev/null; then
    echo "✓ 可以ping通雷达IP: $LIDAR_IP"
    MAC=$(arp -a | grep "$LIDAR_IP" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}' | head -1)
    echo "  MAC地址: $MAC"
else
    echo "✗ 无法ping通雷达IP: $LIDAR_IP"
fi

# 检查UDP端口
echo -e "\n[4] 检查UDP端口监听"
echo "----------------------------------------"
PORTS=(56101 56201 56301 56401 56501)
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✓ 端口 $port 正在监听"
    else
        echo "✗ 端口 $port 未监听"
    fi
done

# 检查配置文件
echo -e "\n[5] 检查配置文件"
echo "----------------------------------------"
CONFIG_FILE="/home/bingda/ws_livox/src/livox_ros_driver2/config/MID360_config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ 配置文件存在"
    LIDAR_IP_CONFIG=$(grep -oP '"lidar_ip"\s*:\s*\["[^"]*"' "$CONFIG_FILE" | grep -oP '"\K[^"]+')
    HOST_IP_CONFIG=$(grep -oP '"host_ip"\s*:\s*"[^"]*"' "$CONFIG_FILE" | grep -oP '"\K[^"]+')
    echo "  配置的雷达IP: $LIDAR_IP_CONFIG"
    echo "  配置的主机IP: $HOST_IP_CONFIG"
    
    CURRENT_HOST_IP=$(ip addr show eth0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    if [ "$CURRENT_HOST_IP" = "$HOST_IP_CONFIG" ]; then
        echo "  ✓ 主机IP匹配"
    else
        echo "  ✗ 主机IP不匹配 (当前: $CURRENT_HOST_IP, 配置: $HOST_IP_CONFIG)"
    fi
else
    echo "✗ 配置文件不存在"
fi

# 建议
echo -e "\n[6] 诊断建议"
echo "----------------------------------------"
if [ -z "$TOPICS" ]; then
    echo "问题: 话题未创建，雷达可能没有发送数据"
    echo ""
    echo "可能的原因和解决方案："
    echo "1. 雷达未开始扫描"
    echo "   - 使用Livox Viewer检查雷达状态"
    echo "   - 确保雷达已上电并正常工作"
    echo ""
    echo "2. 等待时间不够"
    echo "   - 雷达连接可能需要30-60秒"
    echo "   - 请等待更长时间后再检查"
    echo ""
    echo "3. 网络配置问题"
    echo "   - 检查主机IP是否为 192.168.1.100"
    echo "   - 检查雷达IP是否为 192.168.1.175"
    echo ""
    echo "4. 重启节点"
    echo "   - 停止当前节点: pkill -f livox_ros_driver2_node"
    echo "   - 重新启动: ros2 launch livox_ros_driver2 msg_MID360_launch.py"
else
    echo "✓ 话题已创建，雷达连接正常"
    echo ""
    echo "可以查看数据："
    echo "  ros2 topic echo /livox/lidar"
    echo "  ros2 topic hz /livox/lidar"
fi

echo ""
echo "=========================================="

