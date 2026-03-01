#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Livox MID360 雷达数据读取示例
支持两种数据格式：
1. PointCloud2格式 (sensor_msgs/PointCloud2) - xfer_format=0
2. CustomMsg格式 (livox_ros_driver2/CustomMsg) - xfer_format=1
"""

import rospy
import numpy as np
from sensor_msgs.msg import PointCloud2
import sensor_msgs.point_cloud2 as pc2
from livox_ros_driver2.msg import CustomMsg


def callback_pointcloud2(msg):
    """PointCloud2格式的回调函数"""
    # 将PointCloud2消息转换为点云数据
    points = list(pc2.read_points(msg, field_names=("x", "y", "z", "intensity"), skip_nans=True))
    
    if len(points) > 0:
        print(f"收到 {len(points)} 个点")
        # 显示前5个点的信息
        for i, point in enumerate(points[:5]):
            x, y, z, intensity = point
            print(f"  点 {i+1}: x={x:.3f}, y={y:.3f}, z={z:.3f}, intensity={intensity:.3f}")
        print("---")


def callback_custommsg(msg):
    """CustomMsg格式的回调函数"""
    print(f"收到 {msg.point_num} 个点")
    print(f"时间戳: {msg.timebase}")
    print(f"Lidar ID: {msg.lidar_id}")
    
    if len(msg.points) > 0:
        # 显示前5个点的信息
        for i, point in enumerate(msg.points[:5]):
            print(f"  点 {i+1}: x={point.x:.3f}, y={point.y:.3f}, z={point.z:.3f}, "
                  f"reflectivity={point.reflectivity}, tag={point.tag}, line={point.line}")
        print("---")


def listener():
    """主函数：订阅雷达话题"""
    rospy.init_node('livox_lidar_listener', anonymous=True)
    
    # 根据launch文件中的xfer_format参数选择话题类型
    # xfer_format=0: PointCloud2格式 -> /livox/lidar (sensor_msgs/PointCloud2)
    # xfer_format=1: CustomMsg格式 -> /livox/lidar (livox_ros_driver2/CustomMsg)
    
    # 方法1: 订阅PointCloud2格式（如果launch文件中xfer_format=0）
    # rospy.Subscriber("/livox/lidar", PointCloud2, callback_pointcloud2)
    
    # 方法2: 订阅CustomMsg格式（如果launch文件中xfer_format=1，默认值）
    rospy.Subscriber("/livox/lidar", CustomMsg, callback_custommsg)
    
    # 如果multi_topic=1，话题名称可能是 /livox/lidar_192_168_31_157
    # 可以通过 rostopic list 命令查看实际的话题名称
    
    print("等待雷达数据...")
    print("提示：如果收不到数据，请检查：")
    print("  1. 雷达驱动是否正常运行: roslaunch livox_ros_driver2 msg_MID360.launch")
    print("  2. 话题名称是否正确: rostopic list")
    print("  3. 话题是否有数据: rostopic hz /livox/lidar")
    
    rospy.spin()


if __name__ == '__main__':
    try:
        listener()
    except rospy.ROSInterruptException:
        pass

