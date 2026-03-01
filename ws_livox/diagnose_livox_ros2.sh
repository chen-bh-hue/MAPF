#!/bin/bash

# Livox MID360 ROS2 诊断脚本
# 用于排查话题不出现的问题

echo "=========================================="
echo "Livox MID360 ROS2 诊断脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. 检查ROS2环境..."
if command -v ros2 &> /dev/null; then
    ROS2_VERSION=$(ros2 --version 2>/dev/null | head -1)
    check_pass "ROS2已安装: $ROS2_VERSION"
else
    check_fail "ROS2未安装或未在PATH中"
    exit 1
fi

echo ""
echo "2. 检查工作空间..."
if [ -d "$HOME/ws_livox" ]; then
    check_pass "工作空间存在: $HOME/ws_livox"
    cd $HOME/ws_livox
    
    if [ -f "install/setup.bash" ]; then
        check_pass "ROS2工作空间已编译"
        source install/setup.bash 2>/dev/null
    else
        check_warn "工作空间未编译，运行: colcon build"
    fi
else
    check_fail "工作空间不存在: $HOME/ws_livox"
    exit 1
fi

echo ""
echo "3. 检查配置文件..."
CONFIG_FILE="$HOME/ws_livox/src/livox_ros_driver2/config/MID360_config.json"
if [ -f "$CONFIG_FILE" ]; then
    check_pass "配置文件存在"
    
    # 提取配置信息
    LIDAR_IP=$(grep -o '"lidar_ip"[[:space:]]*:[[:space:]]*\["[^"]*"' "$CONFIG_FILE" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    HOST_IP=$(grep -o '"host_ip"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    
    echo "   雷达IP: $LIDAR_IP"
    echo "   主机IP: $HOST_IP"
else
    check_fail "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "4. 检查主机网络配置..."
ACTUAL_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$ACTUAL_IP" ]; then
    echo "   实际主机IP (eth0): $ACTUAL_IP"
    if [ "$ACTUAL_IP" = "$HOST_IP" ]; then
        check_pass "主机IP匹配配置文件"
    else
        check_fail "主机IP不匹配！配置文件中是 $HOST_IP，实际是 $ACTUAL_IP"
        echo "   需要修改配置文件中的 host_ip 为 $ACTUAL_IP"
    fi
else
    check_warn "无法获取eth0的IP地址"
fi

echo ""
echo "5. 检查网络连接..."
if ping -c 1 -W 2 "$LIDAR_IP" &> /dev/null; then
    check_pass "可以ping通雷达: $LIDAR_IP"
else
    check_fail "无法ping通雷达: $LIDAR_IP"
    echo "   请检查："
    echo "   - 雷达是否上电"
    echo "   - 网线是否连接"
    echo "   - 是否在同一网段"
fi

echo ""
echo "6. 检查UDP端口..."
PORTS=(56100 56200 56300 56400 56500)
for port in "${PORTS[@]}"; do
    if sudo netstat -uln 2>/dev/null | grep -q ":$port "; then
        check_warn "端口 $port 已被占用"
    else
        check_pass "端口 $port 可用"
    fi
done

echo ""
echo "7. 检查防火墙..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1)
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        check_pass "防火墙未启用"
    else
        check_warn "防火墙已启用: $UFW_STATUS"
        echo "   可能需要允许UDP端口或临时关闭防火墙测试"
    fi
else
    check_pass "未检测到ufw防火墙"
fi

echo ""
echo "8. 检查ROS2话题..."
if ros2 topic list 2>/dev/null | grep -q livox; then
    check_pass "发现Livox话题："
    ros2 topic list 2>/dev/null | grep livox | sed 's/^/   /'
else
    check_warn "未发现Livox话题"
    echo "   当前话题列表："
    ros2 topic list 2>/dev/null | sed 's/^/   /'
fi

echo ""
echo "9. 检查驱动进程..."
if pgrep -f livox_ros_driver2_node > /dev/null; then
    check_pass "驱动进程正在运行"
    echo "   进程信息："
    ps aux | grep livox_ros_driver2_node | grep -v grep | sed 's/^/   /'
else
    check_warn "驱动进程未运行"
    echo "   请先启动驱动: ros2 launch livox_ros_driver2 msg_MID360_launch.py"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "建议操作："
echo "1. 如果主机IP不匹配，修改配置文件后重新编译"
echo "2. 如果无法ping通雷达，检查网络连接"
echo "3. 如果驱动未运行，启动驱动并等待30-60秒"
echo "4. 使用以下命令持续监控话题："
echo "   watch -n 1 'ros2 topic list'"
echo ""

