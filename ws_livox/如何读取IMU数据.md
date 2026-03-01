# 如何读取Livox IMU数据

Livox MID360雷达的IMU数据发布在 `/livox/imu` 话题上，消息类型是 `sensor_msgs/Imu`。

## 方法1: 使用rostopic命令（最简单）

### 查看IMU数据
```bash
# 实时打印所有IMU数据
rostopic echo /livox/imu

# 只查看加速度数据
rostopic echo /livox/imu | grep -A 3 "linear_acceleration"

# 只查看角速度数据
rostopic echo /livox/imu | grep -A 3 "angular_velocity"

# 只查看方向数据（四元数）
rostopic echo /livox/imu | grep -A 4 "orientation"

# 查看发布频率（通常100Hz）
rostopic hz /livox/imu
```

### 查看一条消息
```bash
# 查看一条完整的IMU消息
rostopic echo /livox/imu -n 1
```

## 方法2: 使用Python脚本（推荐，格式友好）

使用提供的Python脚本：
```bash
cd ~/ws_livox
source devel/setup.bash
python3 read_imu_data.py
```

脚本会显示：
- **加速度** (m/s²): X, Y, Z 和总加速度
- **角速度** (rad/s): X, Y, Z 和总角速度
- **方向** (四元数): X, Y, Z, W
- **欧拉角** (度): Roll, Pitch, Yaw

## 方法3: 使用rosbag录制和回放

### 录制IMU数据
```bash
# 只录制IMU数据
rosbag record /livox/imu

# 录制IMU和点云数据
rosbag record /livox/imu /livox/lidar

# 录制到指定文件
rosbag record -O imu_data.bag /livox/imu
```

### 回放并查看
```bash
# 回放bag文件
rosbag play imu_data.bag

# 回放时查看数据
rosbag play imu_data.bag &
rostopic echo /livox/imu
```

## IMU数据字段说明

### sensor_msgs/Imu 消息结构

```yaml
header:
  seq: 消息序列号
  stamp: 时间戳
  frame_id: 坐标系ID（通常是"livox_frame"）

orientation:
  x, y, z, w: 四元数表示的方向
  covariance: 协方差矩阵（9x9）

angular_velocity:
  x, y, z: 角速度 (rad/s)
  covariance: 协方差矩阵（9x9）

linear_acceleration:
  x, y, z: 线性加速度 (m/s²)
  covariance: 协方差矩阵（9x9）
```

### 数据单位

- **加速度**: 米每秒平方 (m/s²)
  - 静止时，Z轴应该接近 9.8 m/s²（重力加速度）
  - X, Y轴应该接近 0

- **角速度**: 弧度每秒 (rad/s)
  - 静止时应该接近 0
  - 旋转时会有相应的值

- **方向**: 四元数 (x, y, z, w)
  - 可以转换为欧拉角（Roll, Pitch, Yaw）
  - Roll: 绕X轴旋转（横滚）
  - Pitch: 绕Y轴旋转（俯仰）
  - Yaw: 绕Z轴旋转（偏航）

## 快速检查

```bash
# 1. 检查话题是否存在
rostopic list | grep imu

# 2. 检查话题类型
rostopic type /livox/imu

# 3. 检查发布频率（应该接近100Hz）
rostopic hz /livox/imu

# 4. 查看一条消息
rostopic echo /livox/imu -n 1
```

## 实际应用示例

### 示例1: 监控IMU数据频率
```bash
# 持续监控IMU发布频率
watch -n 1 'rostopic hz /livox/imu'
```

### 示例2: 保存IMU数据到文件
```bash
# 录制10秒的IMU数据
timeout 10 rosbag record /livox/imu

# 或使用Python脚本处理并保存
python3 read_imu_data.py > imu_log.txt
```

### 示例3: 实时查看加速度
```bash
# 只显示加速度数据
rostopic echo /livox/imu | grep --line-buffered "linear_acceleration"
```

## 常见问题

### Q: IMU数据频率是多少？
A: 通常为100Hz，可以使用 `rostopic hz /livox/imu` 查看实际频率。

### Q: 如何判断IMU是否正常工作？
A: 
- 检查发布频率是否正常（接近100Hz）
- 静止时，Z轴加速度应该接近9.8 m/s²（重力）
- 静止时，角速度应该接近0

### Q: 如何将四元数转换为欧拉角？
A: 使用提供的Python脚本 `read_imu_data.py`，它会自动转换并显示。

### Q: 如何同时读取点云和IMU数据？
A: 
```bash
# 方法1: 使用两个终端分别运行
# 终端1:
python3 read_lidar_data.py
# 终端2:
python3 read_imu_data.py

# 方法2: 修改Python脚本，同时订阅两个话题
```

## 修改Python脚本同时读取点云和IMU

如果需要同时读取点云和IMU数据，可以修改脚本：

```python
import rospy
from sensor_msgs.msg import Imu
from livox_ros_driver2.msg import CustomMsg

def callback_lidar(msg):
    print(f"点云: {msg.point_num} 个点")

def callback_imu(msg):
    print(f"IMU: accel=({msg.linear_acceleration.x:.2f}, {msg.linear_acceleration.y:.2f}, {msg.linear_acceleration.z:.2f})")

rospy.init_node('livox_listener')
rospy.Subscriber("/livox/lidar", CustomMsg, callback_lidar)
rospy.Subscriber("/livox/imu", Imu, callback_imu)
rospy.spin()
```

## 总结

**最简单的方法**:
```bash
rostopic echo /livox/imu
```

**最友好的方法**:
```bash
python3 read_imu_data.py
```

**录制数据**:
```bash
rosbag record /livox/imu
```

