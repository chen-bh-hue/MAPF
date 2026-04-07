#!/bin/bash
# 能 ping 通雷达但收不到数据时的诊断脚本
# 用法: ./diagnose_no_data.sh [配置文件路径]
# 若未指定，则使用脚本所在目录下的 config/MID360_config.json

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="$SCRIPT_DIR/src/livox_ros_driver2/config/MID360_config.json"
CONFIG_JSON="${1:-$DEFAULT_CONFIG}"
if [ ! -f "$CONFIG_JSON" ]; then
  echo "未找到配置文件: $CONFIG_JSON"
  echo "请指定路径: $0 /path/to/MID360_config.json"
  exit 1
fi

# 从配置文件读取
LIDAR_IP=$(grep -oP '"lidar_ip"\s*:\s*\[\s*"\K[0-9.]+' "$CONFIG_JSON" 2>/dev/null | head -1)
HOST_IP=$(grep -oP '"host_ip"\s*:\s*"\K[0-9.]+' "$CONFIG_JSON" 2>/dev/null | head -1)
MULTICAST_IP=$(grep -oP '"multicast_ip"\s*:\s*"\K[0-9.]+' "$CONFIG_JSON" 2>/dev/null | head -1)

[ -z "$LIDAR_IP" ] && LIDAR_IP="192.168.1.157"
[ -z "$HOST_IP" ] && HOST_IP="192.168.1.100"
[ -z "$MULTICAST_IP" ] && MULTICAST_IP="224.1.1.5"

echo "=============================================="
echo "  Livox 能 ping 通但收不到数据 - 诊断"
echo "=============================================="
echo "配置: lidar_ip=$LIDAR_IP, host_ip=$HOST_IP, multicast_ip=$MULTICAST_IP"
echo ""

# 1. 本机 IP 是否与 host_ip 一致
echo "[1] 检查 host_ip 是否为本机 IP（与雷达同网段）"
echo "----------------------------------------------"
CURRENT_IP=""
for iface in /sys/class/net/*; do
  [ -d "$iface" ] || continue
  name=$(basename "$iface")
  [ "$name" = "lo" ] && continue
  ip=$(ip -4 addr show "$name" 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -1)
  if [ -n "$ip" ]; then
    echo "  接口 $name: $ip"
    if [ "$ip" = "$HOST_IP" ]; then
      CURRENT_IP="$ip"
      echo "  -> 与 host_ip 一致，正确"
    fi
  fi
done
if [ -z "$CURRENT_IP" ]; then
  echo "  >>> 警告: 本机没有接口 IP 为 $HOST_IP"
  echo "  >>> 请把配置文件中的 host_ip 改为本机与雷达同网段的 IP（例如 eth0 的 IP）"
  echo ""
fi

# 2. Ping 雷达
echo ""
echo "[2] Ping 雷达"
echo "----------------------------------------------"
if ping -c 1 -W 2 "$LIDAR_IP" &>/dev/null; then
  echo "  可以 ping 通 $LIDAR_IP"
else
  echo "  无法 ping 通 $LIDAR_IP（请先解决网络连接）"
fi

# 3. 防火墙 / 端口
echo ""
echo "[3] 防火墙与 UDP 端口"
echo "----------------------------------------------"
PORTS="56101 56201 56301 56401 56501"
for p in $PORTS; do
  if command -v ss &>/dev/null; then
    if ss -uln | grep -q ":$p "; then
      echo "  端口 $p: 已在监听"
    else
      echo "  端口 $p: 未监听（驱动未启动或未绑定）"
    fi
  else
    netstat -uln 2>/dev/null | grep -q ":$p " && echo "  端口 $p: 已在监听" || echo "  端口 $p: 未监听"
  fi
done
if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
  echo "  >>> ufw 已启用，请确认允许上述 UDP 端口入站"
  echo "      例如: sudo ufw allow 56101:56501/udp"
fi
if command -v iptables &>/dev/null && sudo iptables -L -n 2>/dev/null | grep -q DROP; then
  echo "  >>> 存在 iptables 规则，请确认未丢弃上述端口的 UDP"
fi

# 4. 多播
echo ""
echo "[4] 多播组 $MULTICAST_IP"
echo "----------------------------------------------"
if ip maddr show 2>/dev/null | grep -q "$MULTICAST_IP"; then
  echo "  已加入多播组 $MULTICAST_IP"
else
  echo "  >>> 未加入多播组 $MULTICAST_IP（点云若走多播会收不到）"
  echo "      驱动正常启动后会自动加入；若仍无数据，可尝试去掉 multicast_ip 或换网络环境"
fi

# 5. 抓包建议
echo ""
echo "[5] 确认是否有 UDP 数据到达"
echo "----------------------------------------------"
echo "  在 驱动已启动 的情况下，另开终端执行（需 root）："
echo "  sudo tcpdump -i any -n udp port 56301"
echo "  若能看到持续有包，说明数据已到本机，问题在驱动/ROS；若无包，多为网络/防火墙/多播或 host_ip 错误。"
echo ""

# 6. 配置小结
echo "=============================================="
echo "  建议检查清单"
echo "=============================================="
echo "  1. host_ip 必须是 本机 与雷达同网段的 IP（如 eth0 的 192.168.1.100）"
echo "  2. 防火墙放行 UDP 56101~56501（及多播若使用）"
echo "  3. 点云若使用多播，确认当前网络支持多播（部分 WiFi/交换机会限制）"
echo "  4. 驱动启动后等待约 10~30 秒再看话题"
echo "  5. 用 tcpdump 看 56301 端口是否有 UDP 包"
echo ""
