#!/bin/bash
# Livox雷达故障排查脚本

echo "=========================================="
echo "Livox MID360 故障排查指南"
echo "=========================================="
echo ""

# 1. 检查雷达IP配置
echo "步骤1: 检查雷达IP配置"
echo "-------------------"
LIDAR_IP="192.168.31.157"
echo "配置的雷达IP: $LIDAR_IP"
echo ""
echo "请确认："
echo "  1. 雷达实际IP地址（查看雷达标签或使用Livox Viewer软件）"
echo "  2. 如果IP不同，请修改配置文件中的IP地址"
echo ""

# 2. 检查网络连接
echo "步骤2: 检查网络连接"
echo "-------------------"
echo "尝试使用arp命令查找雷达："
arp -a | grep -E "192.168.31" || echo "  未找到192.168.31.x网段的设备"
echo ""

# 3. 检查配置文件
echo "步骤3: 检查配置文件"
echo "-------------------"
CONFIG_FILE="/home/bingda/ws_livox/src/livox_ros_driver2/config/MID360_config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "配置文件: $CONFIG_FILE"
    echo "雷达IP配置:"
    grep -A 2 "lidar_ip" "$CONFIG_FILE" | head -3
    echo "主机IP配置:"
    grep "host_ip" "$CONFIG_FILE" | head -1
    echo "多播IP配置:"
    grep "multicast_ip" "$CONFIG_FILE" | head -1
else
    echo "[错误] 配置文件不存在: $CONFIG_FILE"
fi
echo ""

# 4. 检查驱动日志
echo "步骤4: 检查驱动日志"
echo "-------------------"
if pgrep -f "livox_ros_driver2_node" > /dev/null; then
    PID=$(pgrep -f livox_ros_driver2_node)
    echo "驱动进程PID: $PID"
    echo ""
    echo "最近的日志文件："
    LOG_DIR="$HOME/.ros/log"
    if [ -d "$LOG_DIR" ]; then
        LATEST_LOG=$(find "$LOG_DIR" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$LATEST_LOG" ]; then
            echo "日志文件: $LATEST_LOG"
            echo "最后20行日志："
            tail -20 "$LATEST_LOG" 2>/dev/null | grep -E "error|Error|ERROR|fail|Fail|FAIL|warn|Warn|WARN|info|Info|INFO" | tail -10
        fi
    fi
else
    echo "[警告] 驱动进程未运行"
fi
echo ""

# 5. 提供解决方案
echo "=========================================="
echo "可能的解决方案"
echo "=========================================="
echo ""
echo "方案1: 确认雷达IP地址"
echo "  - 使用Livox Viewer软件连接雷达，查看实际IP"
echo "  - 或查看雷达设备标签上的IP地址"
echo "  - 如果IP不同，修改配置文件中的lidar_ip"
echo ""
echo "方案2: 检查网络连接"
echo "  - 确认雷达和主机在同一网段"
echo "  - 尝试直接连接（不使用交换机/路由器）"
echo "  - 检查网线连接"
echo ""
echo "方案3: 检查防火墙"
echo "  - 临时关闭防火墙测试："
echo "    sudo ufw disable  # Ubuntu/Debian"
echo "    sudo iptables -F   # 清空iptables规则"
echo ""
echo "方案4: 使用Livox Viewer验证"
echo "  - 下载并安装Livox Viewer"
echo "  - 使用Viewer连接雷达，确认雷达正常工作"
echo "  - 如果Viewer能连接，说明雷达正常，问题在ROS驱动配置"
echo ""
echo "方案5: 检查多播设置"
echo "  - 确认多播IP: 224.1.1.5"
echo "  - 某些网络设备可能不支持多播，尝试直连"
echo ""
echo "方案6: 查看详细驱动输出"
echo "  重新启动驱动并查看完整输出："
echo "  roslaunch livox_ros_driver2 msg_MID360.launch"
echo "  注意查看是否有连接错误或超时信息"
echo ""

