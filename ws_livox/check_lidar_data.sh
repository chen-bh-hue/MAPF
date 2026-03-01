#!/bin/bash
# 检查Livox雷达数据接收情况

echo "=========================================="
echo "Livox MID360 数据接收诊断"
echo "=========================================="
echo ""

# 检查是否有UDP数据包到达
echo "1. 检查UDP数据包接收..."
echo "   监听端口 56301 (点云数据端口) 5秒钟..."

# 使用ss命令检查接收队列
if command -v ss >/dev/null 2>&1; then
    echo "   当前UDP连接状态："
    ss -uln | grep -E "56101|56201|56301|56401|56501" | while read line; do
        echo "     $line"
    done
fi

# 检查是否有数据包统计
echo ""
echo "2. 检查网络接口统计..."
if [ -f /proc/net/snmp ]; then
    echo "   UDP接收统计："
    grep -A 1 "^Udp:" /proc/net/snmp | tail -1 | awk '{print "     接收数据包: " $2 ", 错误: " $3 ", 丢弃: " $4}'
fi

# 检查多播组
echo ""
echo "3. 检查多播组状态..."
MULTICAST_IP="224.1.1.5"
if ip maddr show | grep -q "$MULTICAST_IP"; then
    echo "   [OK] 已加入多播组 $MULTICAST_IP"
    ip maddr show | grep "$MULTICAST_IP" | head -1
else
    echo "   [错误] 未加入多播组 $MULTICAST_IP"
fi

# 检查ROS话题和消息
echo ""
echo "4. 检查ROS话题和消息..."
if rostopic list 2>/dev/null | grep -q "livox"; then
    echo "   [OK] 发现Livox话题"
    for topic in $(rostopic list | grep livox); do
        echo "     话题: $topic"
        msg_count=$(timeout 2 rostopic echo $topic 2>/dev/null | wc -l)
        if [ $msg_count -gt 0 ]; then
            echo "     [OK] 收到 $msg_count 行数据"
        else
            echo "     [警告] 未收到数据"
        fi
    done
else
    echo "   [警告] 未发现Livox话题"
    echo "   持续监控话题出现（10秒）..."
    for i in {1..10}; do
        if rostopic list 2>/dev/null | grep -q "livox"; then
            echo "   [OK] 话题已出现！"
            rostopic list | grep livox
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
fi

# 检查驱动日志
echo ""
echo "5. 检查驱动进程状态..."
if pgrep -f "livox_ros_driver2_node" > /dev/null; then
    PID=$(pgrep -f livox_ros_driver2_node)
    echo "   [OK] 驱动进程运行中 (PID: $PID)"
    
    # 检查进程的网络连接
    if [ -d /proc/$PID/fd ]; then
        udp_fds=$(ls -l /proc/$PID/fd 2>/dev/null | grep -c "socket")
        echo "   打开的网络套接字: $udp_fds"
    fi
else
    echo "   [错误] 驱动进程未运行"
fi

# 提供建议
echo ""
echo "=========================================="
echo "诊断建议"
echo "=========================================="
echo ""
echo "如果话题仍未出现，请检查："
echo ""
echo "1. 雷达硬件状态："
echo "   - 检查雷达LED指示灯（应该闪烁或常亮）"
echo "   - 确认雷达已上电"
echo ""
echo "2. 网络配置："
echo "   - 确认雷达IP: 192.168.31.157"
echo "   - 确认主机IP: 192.168.31.25"
echo "   - 确认在同一网段（192.168.31.x）"
echo ""
echo "3. 防火墙设置："
echo "   - 检查是否阻止了UDP端口"
echo "   - 尝试临时关闭防火墙测试"
echo ""
echo "4. 查看驱动日志："
echo "   在启动驱动的终端查看是否有错误信息"
echo ""
echo "5. 尝试重启驱动："
echo "   roslaunch livox_ros_driver2 msg_MID360.launch"
echo ""

