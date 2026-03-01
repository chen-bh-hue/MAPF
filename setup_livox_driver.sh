#!/bin/bash

# Livox雷达驱动配置脚本
# 用于在新机器上配置已存在的Livox雷达驱动

set -e  # 遇到错误立即退出

echo "=========================================="
echo "Livox雷达驱动配置脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 路径定义
LIVOX_SDK2_PATH="/home/bingda/Livox-SDK2"
WS_LIVOX_PATH="/home/bingda/ws_livox"

# 检查路径是否存在
if [ ! -d "$LIVOX_SDK2_PATH" ]; then
    echo -e "${RED}错误: Livox-SDK2目录不存在: $LIVOX_SDK2_PATH${NC}"
    exit 1
fi

if [ ! -d "$WS_LIVOX_PATH" ]; then
    echo -e "${RED}错误: ws_livox工作空间不存在: $WS_LIVOX_PATH${NC}"
    exit 1
fi

# 步骤1: 检查ROS环境
echo -e "\n${GREEN}[步骤1] 检查ROS环境...${NC}"
if [ -z "$ROS_DISTRO" ]; then
    echo -e "${YELLOW}警告: ROS环境未设置，尝试source /opt/ros/noetic/setup.bash${NC}"
    source /opt/ros/noetic/setup.bash 2>/dev/null || {
        echo -e "${RED}错误: 无法找到ROS安装，请先安装ROS${NC}"
        exit 1
    }
fi
echo -e "${GREEN}ROS版本: $ROS_DISTRO${NC}"

# 步骤2: 检查并安装依赖
echo -e "\n${GREEN}[步骤2] 检查依赖包...${NC}"
MISSING_DEPS=()

# 检查cmake
if ! command -v cmake &> /dev/null; then
    MISSING_DEPS+=("cmake")
fi

# 检查PCL
if ! pkg-config --exists pcl_common-1.10 2>/dev/null && ! pkg-config --exists pcl_common-1.8 2>/dev/null; then
    MISSING_DEPS+=("libpcl-dev")
fi

# 检查apr
if ! pkg-config --exists apr-1 2>/dev/null; then
    MISSING_DEPS+=("libapr1-dev")
fi

# 检查ROS依赖（ROS1）
if [ "$ROS_DISTRO" = "noetic" ] || [ -n "$ROS_VERSION" ]; then
    if ! dpkg -l | grep -q "ros-$ROS_DISTRO-pcl-ros"; then
        MISSING_DEPS+=("ros-$ROS_DISTRO-pcl-ros")
    fi
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${YELLOW}发现缺失的依赖: ${MISSING_DEPS[*]}${NC}"
    echo "是否安装这些依赖? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y "${MISSING_DEPS[@]}"
    else
        echo -e "${RED}请手动安装依赖后重新运行此脚本${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}所有依赖已安装${NC}"
fi

# 步骤3: 编译安装Livox-SDK2
echo -e "\n${GREEN}[步骤3] 编译安装Livox-SDK2...${NC}"
if [ -f "/usr/local/lib/liblivox_lidar_sdk_static.a" ] || [ -f "/usr/local/lib/liblivox_lidar_sdk_shared.so" ]; then
    echo -e "${YELLOW}Livox SDK已安装，跳过编译${NC}"
else
    cd "$LIVOX_SDK2_PATH"
    if [ ! -d "build" ]; then
        mkdir build
    fi
    cd build
    echo "运行cmake..."
    cmake .. || {
        echo -e "${RED}cmake失败${NC}"
        exit 1
    }
    echo "编译中..."
    make -j$(nproc) || {
        echo -e "${RED}编译失败${NC}"
        exit 1
    }
    echo "安装中..."
    sudo make install || {
        echo -e "${RED}安装失败${NC}"
        exit 1
    }
    echo -e "${GREEN}Livox-SDK2安装完成${NC}"
fi

# 步骤4: 配置网络IP地址
echo -e "\n${GREEN}[步骤4] 配置网络IP地址...${NC}"
CONFIG_FILE="$WS_LIVOX_PATH/src/livox_ros_driver2/config/MID360_config.json"
if [ -f "$CONFIG_FILE" ]; then
    CURRENT_HOST_IP=$(ip addr show | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1)
    CONFIG_HOST_IP=$(grep -oP '"host_ip"\s*:\s*"\K[^"]+' "$CONFIG_FILE" | head -1)
    
    echo "当前主机IP: $CURRENT_HOST_IP"
    echo "配置文件中的IP: $CONFIG_HOST_IP"
    
    if [ "$CURRENT_HOST_IP" != "$CONFIG_HOST_IP" ]; then
        echo -e "${YELLOW}IP地址不匹配！${NC}"
        echo "是否更新配置文件中的IP地址为 $CURRENT_HOST_IP? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # 备份原配置文件
            cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
            # 更新IP地址
            sed -i "s/\"host_ip\"\\s*:\\s*\"[^\"]*\"/\"host_ip\": \"$CURRENT_HOST_IP\"/g" "$CONFIG_FILE"
            echo -e "${GREEN}配置文件已更新${NC}"
        else
            echo -e "${YELLOW}请确保网络接口配置为: $CONFIG_HOST_IP${NC}"
        fi
    else
        echo -e "${GREEN}IP地址配置正确${NC}"
    fi
else
    echo -e "${YELLOW}警告: 配置文件不存在: $CONFIG_FILE${NC}"
fi

# 步骤5: 编译ROS工作空间
echo -e "\n${GREEN}[步骤5] 编译ROS工作空间...${NC}"
cd "$WS_LIVOX_PATH"

# 检查是ROS1还是ROS2
if [ -f "src/CMakeLists.txt" ] || [ -d "devel" ]; then
    ROS_EDITION="ROS1"
    echo "检测到ROS1工作空间"
else
    ROS_EDITION="ROS2"
    echo "检测到ROS2工作空间"
fi

# 根据ROS版本编译
if [ "$ROS_EDITION" = "ROS1" ]; then
    # ROS1使用catkin_make
    echo "使用catkin_make编译..."
    source /opt/ros/noetic/setup.bash
    catkin_make -DROS_EDITION=ROS1 || {
        echo -e "${RED}编译失败${NC}"
        exit 1
    }
    echo -e "${GREEN}编译完成${NC}"
else
    # ROS2使用colcon
    echo "使用colcon编译..."
    source /opt/ros/*/setup.bash
    colcon build --cmake-args -DROS_EDITION=ROS2 || {
        echo -e "${RED}编译失败${NC}"
        exit 1
    }
    echo -e "${GREEN}编译完成${NC}"
fi

# 步骤6: 配置环境变量
echo -e "\n${GREEN}[步骤6] 配置环境变量...${NC}"
BASHRC_FILE="$HOME/.bashrc"

# 检查是否已添加
if ! grep -q "ws_livox" "$BASHRC_FILE"; then
    echo "" >> "$BASHRC_FILE"
    echo "# Livox雷达驱动环境配置" >> "$BASHRC_FILE"
    if [ "$ROS_EDITION" = "ROS1" ]; then
        echo "source $WS_LIVOX_PATH/devel/setup.bash" >> "$BASHRC_FILE"
    else
        echo "source $WS_LIVOX_PATH/install/setup.bash" >> "$BASHRC_FILE"
    fi
    echo -e "${GREEN}已添加环境变量到 ~/.bashrc${NC}"
else
    echo -e "${YELLOW}环境变量已存在${NC}"
fi

# 步骤7: 验证安装
echo -e "\n${GREEN}[步骤7] 验证安装...${NC}"

# 检查SDK库
if [ -f "/usr/local/lib/liblivox_lidar_sdk_static.a" ] || [ -f "/usr/local/lib/liblivox_lidar_sdk_shared.so" ]; then
    echo -e "${GREEN}✓ Livox SDK库已安装${NC}"
else
    echo -e "${RED}✗ Livox SDK库未找到${NC}"
fi

# 检查ROS包
if [ "$ROS_EDITION" = "ROS1" ]; then
    source "$WS_LIVOX_PATH/devel/setup.bash"
    if rospack find livox_ros_driver2 &> /dev/null; then
        echo -e "${GREEN}✓ ROS包已正确安装${NC}"
    else
        echo -e "${RED}✗ ROS包未找到${NC}"
    fi
else
    source "$WS_LIVOX_PATH/install/setup.bash"
    if ros2 pkg list | grep -q livox_ros_driver2; then
        echo -e "${GREEN}✓ ROS2包已正确安装${NC}"
    else
        echo -e "${RED}✗ ROS2包未找到${NC}"
    fi
fi

echo -e "\n${GREEN}=========================================="
echo "配置完成！"
echo "==========================================${NC}"
echo ""
echo "下一步操作："
echo "1. 重新打开终端或运行: source ~/.bashrc"
echo "2. 连接雷达到网络"
echo "3. 确保主机IP与配置文件中的host_ip匹配"
echo "4. 启动驱动:"
if [ "$ROS_EDITION" = "ROS1" ]; then
    echo "   roslaunch livox_ros_driver2 msg_MID360.launch"
else
    echo "   ros2 launch livox_ros_driver2 msg_MID360_launch.py"
fi
echo ""
echo "配置文件位置: $CONFIG_FILE"
echo "工作空间位置: $WS_LIVOX_PATH"
echo ""

