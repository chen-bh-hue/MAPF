#!/bin/bash
# Livox MID360 雷达连接诊断脚本

echo "=========================================="
echo "Livox MID360 雷达连接诊断"
echo "=========================================="
echo ""

# 检查ROS环境
echo "1. 检查ROS环境..."
if [ -z "$ROS_MASTER_URI" ]; then
    echo "   [警告] ROS_MASTER_URI 未设置"
else
    echo "   [OK] ROS_MASTER_URI: $ROS_MASTER_URI"
fi

# 检查网络连接
echo ""
echo "2. 检查网络连接..."
LIDAR_IP="192.168.31.157"
HOST_IP="192.168.31.25"

echo "   雷达IP: $LIDAR_IP"
echo "   主机IP: $HOST_IP"

# Ping雷达
if ping -c 1 -W 2 $LIDAR_IP > /dev/null 2>&1; then
    echo "   [OK] 可以ping通雷达 $LIDAR_IP"
else
    echo "   [错误] 无法ping通雷达 $LIDAR_IP"
    echo "   请检查："
    echo "     - 雷达是否上电"
    echo "     - 网络连接是否正常"
    echo "     - IP地址配置是否正确"
fi

# 检查主机IP
if ip addr show | grep -q "$HOST_IP"; then
    echo "   [OK] 主机IP $HOST_IP 已配置"
else
    echo "   [警告] 主机IP $HOST_IP 未找到"
    echo "   当前IP地址："
    ip addr show | grep "inet " | grep -v "127.0.0.1"
fi

# 检查端口
echo ""
echo "3. 检查端口占用..."
PORTS=(56100 56200 56300 56400 56500 56101 56201 56301 56401 56501)
for port in "${PORTS[@]}"; do
    if netstat -uln 2>/dev/null | grep -q ":$port "; then
        echo "   [OK] 端口 $port 已监听"
    fi
done

# 检查ROS话题
echo ""
echo "4. 检查ROS话题..."
if rostopic list 2>/dev/null | grep -q "livox"; then
    echo "   [OK] 发现Livox话题："
    rostopic list | grep livox
    echo ""
    echo "   话题信息："
    for topic in $(rostopic list | grep livox); do
        echo "     - $topic: $(rostopic type $topic 2>/dev/null)"
        freq=$(rostopic hz $topic 2>/dev/null | head -1)
        if [ ! -z "$freq" ]; then
            echo "       发布频率: $freq"
        fi
    done
else
    echo "   [警告] 未发现Livox话题"
    echo "   可能原因："
    echo "     - 驱动未启动或已停止"
    echo "     - 雷达未连接或未发送数据"
    echo "     - 话题延迟创建（需要等待数据）"
fi

# 检查驱动进程
echo ""
echo "5. 检查驱动进程..."
if pgrep -f "livox_ros_driver2_node" > /dev/null; then
    echo "   [OK] 驱动进程正在运行"
    echo "   PID: $(pgrep -f livox_ros_driver2_node)"
else
    echo "   [错误] 驱动进程未运行"
    echo "   请运行: roslaunch livox_ros_driver2 msg_MID360.launch"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "提示："
echo "1. 话题是延迟创建的，只有在有数据时才会出现"
echo "2. 如果驱动已启动但没有话题，请等待几秒钟让雷达连接"
echo "3. 使用 'rostopic list' 持续监控话题出现"
echo "4. 如果长时间没有话题，检查雷达是否正常工作"

