# MAPF
source ws_livox/install/setup.bash
source ros2_ws/install/setup.bash

## Livox 没有 `/livox/lidar` 时
改 `src/livox_ros_driver2/config/MID360_config.json` 后执行：
cd ~/ws_livox && source /opt/ros/foxy/setup.bash && colcon build --packages-select livox_ros_driver2 --symlink-install
再重新 source、启动 launch。

## 整车 launch 用命名空间 `car_X`
`ros2 launch robot_navigation_ros2 robot_livox.launch.py car_id:=car_2`（或 `topic_prefix:=/car_2`）。  
`ros2 run` 的 `--ros-args -r __ns:=` 不会自动套到 launch 里每个节点，请用上面参数。
