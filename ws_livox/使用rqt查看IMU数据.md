# 使用rqt查看Livox IMU数据

rqt是ROS的可视化工具集，提供了多种插件来查看和监控ROS话题数据。

## 方法1: 使用rqt_topic（查看话题数据）

### 启动rqt_topic
```bash
cd ~/ws_livox
source devel/setup.bash
rqt
```

### 在rqt中配置：
1. **Plugins** → **Topics** → **Topic Monitor**
   - 选择 `/livox/imu` 话题
   - 可以看到话题的发布频率、消息大小等信息

2. **Plugins** → **Topics** → **Message Publisher**
   - 可以用来发布测试消息

### 或者直接启动rqt_topic
```bash
rqt_topic
```
- 在左侧选择 `/livox/imu` 话题
- 可以看到话题的详细信息

## 方法2: 使用rqt_plot（绘制数据曲线）

### 启动rqt_plot
```bash
cd ~/ws_livox
source devel/setup.bash
rqt_plot
```

### 在rqt_plot中添加数据：
1. 在左上角的输入框中输入：
   ```
   /livox/imu/linear_acceleration/x
   /livox/imu/linear_acceleration/y
   /livox/imu/linear_acceleration/z
   ```
   点击 **+** 添加，可以实时绘制加速度曲线

2. 添加角速度：
   ```
   /livox/imu/angular_velocity/x
   /livox/imu/angular_velocity/y
   /livox/imu/angular_velocity/z
   ```

3. 添加方向（四元数）：
   ```
   /livox/imu/orientation/x
   /livox/imu/orientation/y
   /livox/imu/orientation/z
   /livox/imu/orientation/w
   ```

### 常用绘图配置：
- **加速度曲线**:
  ```
  /livox/imu/linear_acceleration/x
  /livox/imu/linear_acceleration/y
  /livox/imu/linear_acceleration/z
  ```

- **角速度曲线**:
  ```
  /livox/imu/angular_velocity/x
  /livox/imu/angular_velocity/y
  /livox/imu/angular_velocity/z
  ```

- **总加速度**（需要计算）:
  可以添加多个字段，然后手动计算总加速度

## 方法3: 使用rqt_reconfigure（配置参数）

```bash
rqt_reconfigure
```
- 可以用来动态调整ROS节点的参数
- 对于Livox驱动，可以调整发布频率等参数

## 方法4: 使用rqt_bag（查看bag文件）

如果录制了bag文件：
```bash
rqt_bag <bag文件名>
```
- 可以可视化回放bag文件
- 选择 `/livox/imu` 话题查看数据
- 可以暂停、快进、慢放

## 方法5: 使用rqt_gui（综合工具）

```bash
rqt
```

在rqt主窗口中可以同时打开多个插件：
- **Plugins** → **Topics** → **Topic Monitor** - 监控话题
- **Plugins** → **Visualization** → **Plot** - 绘制曲线
- **Plugins** → **Topics** → **Message Publisher** - 发布消息

## 推荐工作流程

### 实时监控IMU数据

**终端1**: 启动驱动
```bash
roslaunch livox_ros_driver2 msg_MID360.launch
```

**终端2**: 启动rqt_plot查看实时曲线
```bash
cd ~/ws_livox
source devel/setup.bash
rqt_plot /livox/imu/linear_acceleration/x /livox/imu/linear_acceleration/y /livox/imu/linear_acceleration/z
```

### 查看话题信息

```bash
rqt_topic
```
- 选择 `/livox/imu` 查看详细信息
- 可以看到发布频率、消息大小等

## rqt_plot使用技巧

### 1. 添加多个数据字段
在输入框中输入多个字段，用空格分隔：
```
/livox/imu/linear_acceleration/x /livox/imu/linear_acceleration/y /livox/imu/linear_acceleration/z
```

### 2. 调整时间窗口
- 右键点击图表 → **Configure** → 调整时间范围
- 可以设置显示最近N秒的数据

### 3. 保存数据
- **File** → **Export** → 可以导出CSV格式的数据

### 4. 暂停/继续
- 点击暂停按钮可以暂停数据更新
- 方便查看特定时刻的数据

## 常用rqt命令

```bash
# 启动rqt主窗口（可以加载多个插件）
rqt

# 启动rqt_plot（绘制曲线）
rqt_plot

# 启动rqt_topic（查看话题）
rqt_topic

# 启动rqt_bag（查看bag文件）
rqt_bag <bag文件>

# 启动rqt_reconfigure（配置参数）
rqt_reconfigure
```

## 实际示例

### 示例1: 实时绘制加速度曲线
```bash
rqt_plot /livox/imu/linear_acceleration/x /livox/imu/linear_acceleration/y /livox/imu/linear_acceleration/z
```

### 示例2: 实时绘制角速度曲线
```bash
rqt_plot /livox/imu/angular_velocity/x /livox/imu/angular_velocity/y /livox/imu/angular_velocity/z
```

### 示例3: 同时查看加速度和角速度
打开两个rqt_plot窗口，或者在一个窗口中添加多个字段。

### 示例4: 在rqt中同时监控多个话题
```bash
rqt
```
然后：
- 打开 **Topic Monitor** 监控 `/livox/imu` 和 `/livox/lidar`
- 打开 **Plot** 绘制IMU数据曲线

## 常见问题

### Q: rqt_plot没有数据显示？
A: 
1. 确认话题存在：`rostopic list | grep imu`
2. 确认话题有数据：`rostopic hz /livox/imu`
3. 检查字段路径是否正确

### Q: 如何调整rqt_plot的时间范围？
A: 右键点击图表 → **Configure** → 调整 **Time window** 参数

### Q: 如何保存rqt_plot的数据？
A: **File** → **Export** → 选择CSV格式保存

### Q: rqt启动很慢怎么办？
A: 直接使用具体的rqt插件，如 `rqt_plot` 而不是 `rqt`

## 总结

**最简单的方法**:
```bash
rqt_plot /livox/imu/linear_acceleration/x /livox/imu/linear_acceleration/y /livox/imu/linear_acceleration/z
```

**最全面的方法**:
```bash
rqt
```
然后在Plugins中选择需要的工具。

**查看bag文件**:
```bash
rqt_bag <bag文件名>
```

rqt提供了非常直观的可视化界面，特别适合实时监控和数据分析！

