#!/bin/bash

# Livox雷达IP查找脚本
# 用于诊断和找到雷达的实际IP地址

echo "=========================================="
echo "Livox雷达IP诊断工具"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 显示主机网络配置
echo -e "\n${BLUE}[1] 主机网络配置${NC}"
echo "----------------------------------------"
ip addr show | grep -E "inet |^[0-9]+:" | grep -A 1 "eth0\|wlan0" | head -10

# 2. 显示ARP表中的完整条目（有MAC地址的）
echo -e "\n${BLUE}[2] ARP表中的活跃设备（有MAC地址）${NC}"
echo "----------------------------------------"
ACTIVE_IPS=$(arp -a | grep -v incomplete | grep -oP '\d+\.\d+\.\d+\.\d+' | sort -u)
if [ -z "$ACTIVE_IPS" ]; then
    echo -e "${YELLOW}未找到有MAC地址的设备${NC}"
else
    echo "找到以下活跃IP地址："
    for ip in $ACTIVE_IPS; do
        mac=$(arp -a | grep "$ip" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}' | head -1)
        echo -e "  ${GREEN}$ip${NC} -> $mac"
    done
fi

# 3. 检查配置的雷达IP（从配置文件读取）
CONFIG_FILE="/home/bingda/ws_livox/src/livox_ros_driver2/config/MID360_config.json"
CONFIG_LIDAR_IP=$(grep -oP '"lidar_ip"\s*:\s*\[\s*"\K[^"]+' "$CONFIG_FILE" 2>/dev/null | head -1)
CONFIG_HOST_IP=$(grep -oP '"host_ip"\s*:\s*"\K[^"]+' "$CONFIG_FILE" 2>/dev/null | head -1)
[ -z "$CONFIG_LIDAR_IP" ] && CONFIG_LIDAR_IP="192.168.1.1"
[ -z "$CONFIG_HOST_IP" ] && CONFIG_HOST_IP="192.168.1.100"
echo -e "\n${BLUE}[3] 检查配置文件中的IP${NC}"
echo "----------------------------------------"
echo "配置的雷达IP: $CONFIG_LIDAR_IP"
echo "配置的主机IP: $CONFIG_HOST_IP"

# 检查主机IP是否匹配
CURRENT_HOST_IP=$(ip addr show eth0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
if [ -z "$CURRENT_HOST_IP" ]; then
    CURRENT_HOST_IP=$(ip addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1)
fi

echo "当前主机IP (eth0): $CURRENT_HOST_IP"

if [ "$CURRENT_HOST_IP" != "$CONFIG_HOST_IP" ]; then
    echo -e "${YELLOW}警告: 主机IP不匹配！${NC}"
    echo "  配置文件中: $CONFIG_HOST_IP"
    echo "  实际主机IP: $CURRENT_HOST_IP"
fi

# 4. 测试雷达IP连接
echo -e "\n${BLUE}[4] 测试雷达IP连接${NC}"
echo "----------------------------------------"
if ping -c 2 -W 1 "$CONFIG_LIDAR_IP" &> /dev/null; then
    echo -e "${GREEN}✓ 可以ping通 $CONFIG_LIDAR_IP${NC}"
else
    echo -e "${RED}✗ 无法ping通 $CONFIG_LIDAR_IP${NC}"
fi

# 5. 扫描可能的雷达IP（192.168.1.x网段）
echo -e "\n${BLUE}[5] 扫描192.168.1.x网段查找雷达${NC}"
echo "----------------------------------------"
echo "正在扫描，这可能需要一些时间..."
FOUND_IPS=()

# 快速扫描常见IP范围
for i in {1..254}; do
    ip="192.168.1.$i"
    # 跳过主机自己的IP
    if [ "$ip" = "$CURRENT_HOST_IP" ]; then
        continue
    fi
    # 快速ping测试
    if timeout 0.1 ping -c 1 -W 1 "$ip" &> /dev/null; then
        FOUND_IPS+=("$ip")
        echo -e "  ${GREEN}找到活跃IP: $ip${NC}"
    fi
done

if [ ${#FOUND_IPS[@]} -eq 0 ]; then
    echo -e "${YELLOW}未找到其他活跃的IP地址${NC}"
else
    echo -e "\n${GREEN}找到 ${#FOUND_IPS[@]} 个活跃IP地址${NC}"
fi

# 6. 检查Livox特定的MAC地址前缀
echo -e "\n${BLUE}[6] 检查ARP表中的MAC地址（查找Livox设备）${NC}"
echo "----------------------------------------"
# Livox设备的MAC地址通常以特定前缀开头
LIVOX_MAC_PREFIXES=("0c:9a" "00:16" "00:1e")
arp -a | while read line; do
    if echo "$line" | grep -q "incomplete"; then
        continue
    fi
    mac=$(echo "$line" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}' | head -1)
    ip=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    if [ -n "$mac" ] && [ -n "$ip" ]; then
        mac_prefix=$(echo "$mac" | cut -d: -f1-2)
        for prefix in "${LIVOX_MAC_PREFIXES[@]}"; do
            if [ "$mac_prefix" = "$prefix" ]; then
                echo -e "  ${GREEN}可能的Livox设备: $ip (MAC: $mac)${NC}"
            fi
        done
    fi
done

# 7. 检查ROS2话题
echo -e "\n${BLUE}[7] 检查ROS2话题${NC}"
echo "----------------------------------------"
if command -v ros2 &> /dev/null; then
    TOPICS=$(ros2 topic list 2>/dev/null | grep livox)
    if [ -z "$TOPICS" ]; then
        echo -e "${YELLOW}未找到livox相关话题${NC}"
        echo "  这可能是因为雷达未连接或IP配置错误"
    else
        echo -e "${GREEN}找到以下话题:${NC}"
        echo "$TOPICS" | sed 's/^/  /'
    fi
else
    echo -e "${YELLOW}ROS2未安装或未source${NC}"
fi

# 8. 建议
echo -e "\n${BLUE}[8] 诊断建议${NC}"
echo "----------------------------------------"

if ! ping -c 1 -W 1 "$CONFIG_LIDAR_IP" &> /dev/null; then
    echo -e "${RED}问题: 无法连接到配置的雷达IP ($CONFIG_LIDAR_IP)${NC}"
    echo ""
    echo "可能的解决方案："
    echo "1. 检查雷达是否上电并连接到网络"
    echo "2. 检查网线连接"
    echo "3. 使用Livox Viewer软件查看雷达实际IP"
    echo "4. 检查ARP表，查找有MAC地址的设备："
    echo "   arp -a | grep -v incomplete"
    echo ""
    if [ ${#FOUND_IPS[@]} -gt 0 ]; then
        echo -e "${YELLOW}建议尝试以下IP地址：${NC}"
        for ip in "${FOUND_IPS[@]}"; do
            echo "  - $ip"
        done
        echo ""
        echo "如果找到正确的IP，请更新配置文件："
        echo "  /home/bingda/ws_livox/src/livox_ros_driver2/config/MID360_config.json"
    fi
else
    echo -e "${GREEN}可以ping通雷达IP，但如果没有话题，请等待30-60秒${NC}"
    echo "话题是延迟创建的，需要等待雷达开始发送数据"
fi

echo ""
echo "=========================================="

