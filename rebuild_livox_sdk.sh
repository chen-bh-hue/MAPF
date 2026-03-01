#!/bin/bash

# 重新构建 Livox SDK 以启用 pcap、png 和 libusb-1.0 功能

set -e

echo "=========================================="
echo "重新构建 Livox SDK2（启用可选功能）"
echo "=========================================="

SCRIPT_DIR="/home/bingda/Livox-SDK2"
cd "$SCRIPT_DIR"

# 检查依赖库是否已安装
echo ""
echo "检查依赖库..."
if ! dpkg -l | grep -q "libpcap-dev"; then
    echo "错误: libpcap-dev 未安装"
    exit 1
fi
if ! dpkg -l | grep -q "libpng-dev"; then
    echo "错误: libpng-dev 未安装"
    exit 1
fi
if ! dpkg -l | grep -q "libusb-1.0-0-dev"; then
    echo "错误: libusb-1.0-0-dev 未安装"
    exit 1
fi
echo "✓ 所有依赖库已安装"

# 清理之前的构建
echo ""
echo "清理之前的构建..."
if [ -d "build" ]; then
    rm -rf build
fi

# 创建构建目录
mkdir -p build
cd build

# 配置 CMake
echo ""
echo "配置 CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# 编译（使用2个并行任务以避免内存问题）
echo ""
echo "开始编译（使用 2 个并行任务）..."
make -j2

# 安装
echo ""
echo "安装 SDK..."
sudo make install

echo ""
echo "=========================================="
echo "Livox SDK 重新构建完成！"
echo "=========================================="
echo "SDK 已安装到 /usr/local/lib"
ls -lh /usr/local/lib/liblivox_lidar_sdk* 2>/dev/null || echo "未找到 SDK 库文件"

echo ""
echo "现在可以重新构建 livox_ros_driver2："
echo "cd ~/ws_livox/src/livox_ros_driver2"
echo "./build.sh ROS2"

