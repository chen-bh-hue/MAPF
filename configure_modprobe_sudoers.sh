#!/bin/bash

# 配置 sudoers 允许免密码执行 modprobe spidev

SUDOERS_FILE="/etc/sudoers.d/modprobe-spidev"
USERNAME=$(whoami)

echo "正在配置 sudoers 以允许用户 $USERNAME 免密码执行 modprobe spidev..."

# 创建 sudoers 配置内容
sudo bash <<EOF
cat > $SUDOERS_FILE <<'SUDOERS_EOF'
# 允许用户免密码执行 modprobe spidev
bingda ALL=(ALL) NOPASSWD: /sbin/modprobe spidev
SUDOERS_EOF

# 设置正确的权限
chmod 0440 $SUDOERS_FILE

# 验证配置语法
visudo -c -f $SUDOERS_FILE

if [ \$? -eq 0 ]; then
    echo "配置成功！sudoers 文件已创建: $SUDOERS_FILE"
    echo "现在可以免密码执行: sudo modprobe spidev"
else
    echo "错误：sudoers 配置语法有误，已删除文件"
    rm -f $SUDOERS_FILE
    exit 1
fi
EOF

