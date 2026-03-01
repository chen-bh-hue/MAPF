#!/bin/bash

echo "=========================================="
echo "Livox ROS2 驱动连接问题排查和修复脚本"
echo "=========================================="

# 1. 停止所有相关进程
echo -e "\n[1] 停止所有相关进程"
echo "----------------------------------------"
pkill -f livox_ros_driver2_node
pkill -f livox_lidar_quick_start
sleep 2
echo "✓ 已停止相关进程"

# 2. 检查网络连接
echo -e "\n[2] 检查网络连接"
echo "----------------------------------------"
LIDAR_IP="192.168.1.175"
if ping -c 3 -W 1 "$LIDAR_IP" &> /dev/null; then
    echo "✓ 可以ping通雷达IP: $LIDAR_IP"
else
    echo "✗ 无法ping通雷达IP: $LIDAR_IP"
    echo "  请检查网络连接和IP配置"
    exit 1
fi

# 3. 检查主机IP
echo -e "\n[3] 检查主机IP配置"
echo "----------------------------------------"
CURRENT_IP=$(ip addr show eth0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
EXPECTED_IP="192.168.1.100"
echo "当前主机IP: $CURRENT_IP"
echo "期望主机IP: $EXPECTED_IP"
if [ "$CURRENT_IP" != "$EXPECTED_IP" ]; then
    echo "⚠ 警告: IP不匹配，但quick_start可以工作，继续..."
fi

# 4. 检查端口占用
echo -e "\n[4] 检查端口占用"
echo "----------------------------------------"
PORTS=(56101 56201 56301 56401 56501)
PORT_FREE=true
for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✗ 端口 $port 被占用"
        PORT_FREE=false
    fi
done
if [ "$PORT_FREE" = true ]; then
    echo "✓ 所有端口都可用"
fi

# 5. 清理ROS2日志（可选）
echo -e "\n[5] 清理旧的ROS2日志"
echo "----------------------------------------"
# 不删除，只提示位置
echo "日志位置: ~/.ros/log/"

# 6. 启动ROS2驱动并等待
echo -e "\n[6] 启动ROS2驱动（等待60秒观察连接）"
echo "----------------------------------------"
echo "正在启动ROS2驱动..."
echo "请等待至少60秒，观察是否有以下输出："
echo "  - 'begin to change work mode to Normal'"
echo "  - 'successfully change work mode'"
echo "  - 'successfully set data type'"
echo ""
echo "如果60秒后仍无数据，请按Ctrl+C停止，然后检查："
echo "  1. 雷达是否正常工作（可以用quick_start测试）"
echo "  2. 配置文件路径是否正确"
echo "  3. SDK是否正确安装"
echo ""

# 启动驱动
timeout 60 ros2 launch livox_ros_driver2 msg_MID360_launch.py 2>&1 | tee /tmp/livox_ros2_connection.log

echo ""
echo "=========================================="
echo "检查日志文件: /tmp/livox_ros2_connection.log"
echo "=========================================="

