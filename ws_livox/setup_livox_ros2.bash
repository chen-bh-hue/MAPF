# 供 ROS2 使用 Livox 时 source，会先加载工作空间再清除 Noetic 路径，避免 class_loader 符号错误
# 用法: source /home/bingda/ws_livox/setup_livox_ros2.bash
# 或先执行 to_ros2 再 source 本脚本

SCRIPT_DIR="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install/setup.bash"
if [ -n "$LD_LIBRARY_PATH" ]; then
  export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v '/opt/ros/noetic' | tr '\n' ':' | sed 's/:$//')
fi
