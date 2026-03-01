#!/bin/bash

# 配置NetworkManager忽略eth0接口

echo "=========================================="
echo "配置NetworkManager忽略eth0接口"
echo "=========================================="

# 创建配置目录
sudo mkdir -p /etc/NetworkManager/conf.d

# 复制配置文件
sudo cp /home/bingda/99-unmanaged-devices.conf /etc/NetworkManager/conf.d/99-unmanaged-devices.conf

echo "✓ 配置文件已创建: /etc/NetworkManager/conf.d/99-unmanaged-devices.conf"

# 检查NetworkManager是否运行
if systemctl is-active --quiet NetworkManager; then
    echo "正在重启NetworkManager..."
    sudo systemctl restart NetworkManager
    echo "✓ NetworkManager已重启"
else
    echo "⚠ NetworkManager未运行，配置将在下次启动时生效"
fi

# 验证配置
echo ""
echo "验证配置..."
if [ -f "/etc/NetworkManager/conf.d/99-unmanaged-devices.conf" ]; then
    echo "✓ 配置文件存在"
    echo ""
    echo "配置文件内容:"
    cat /etc/NetworkManager/conf.d/99-unmanaged-devices.conf
    echo ""
    echo "=========================================="
    echo "配置完成！"
    echo "=========================================="
    echo ""
    echo "NetworkManager现在将忽略eth0接口，不会自动管理它。"
    echo "您可以手动配置eth0的IP地址，它不会被删除。"
    echo ""
    echo "手动配置IP地址:"
    echo "  sudo ip addr add 192.168.1.100/24 dev eth0"
    echo "  sudo ip link set eth0 up"
else
    echo "✗ 配置文件创建失败"
    exit 1
fi

