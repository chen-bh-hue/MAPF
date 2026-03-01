#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Livox MID360 IMU数据读取示例
订阅 /livox/imu 话题，读取IMU数据
"""

import rospy
from sensor_msgs.msg import Imu
import math


def callback_imu(msg):
    """IMU数据的回调函数"""
    # 提取加速度数据 (m/s^2)
    accel_x = msg.linear_acceleration.x
    accel_y = msg.linear_acceleration.y
    accel_z = msg.linear_acceleration.z
    
    # 提取角速度数据 (rad/s)
    gyro_x = msg.angular_velocity.x
    gyro_y = msg.angular_velocity.y
    gyro_z = msg.angular_velocity.z
    
    # 提取四元数方向数据
    quat_x = msg.orientation.x
    quat_y = msg.orientation.y
    quat_z = msg.orientation.z
    quat_w = msg.orientation.w
    
    # 计算欧拉角（roll, pitch, yaw）
    # 从四元数转换为欧拉角
    sinr_cosp = 2 * (quat_w * quat_x + quat_y * quat_z)
    cosr_cosp = 1 - 2 * (quat_x * quat_x + quat_y * quat_y)
    roll = math.atan2(sinr_cosp, cosr_cosp)
    
    sinp = 2 * (quat_w * quat_y - quat_z * quat_x)
    if abs(sinp) >= 1:
        pitch = math.copysign(math.pi / 2, sinp)
    else:
        pitch = math.asin(sinp)
    
    siny_cosp = 2 * (quat_w * quat_z + quat_x * quat_y)
    cosy_cosp = 1 - 2 * (quat_y * quat_y + quat_z * quat_z)
    yaw = math.atan2(siny_cosp, cosy_cosp)
    
    # 转换为度数
    roll_deg = math.degrees(roll)
    pitch_deg = math.degrees(pitch)
    yaw_deg = math.degrees(yaw)
    
    # 打印IMU数据
    print("=" * 60)
    print(f"时间戳: {msg.header.stamp.secs}.{msg.header.stamp.nsecs}")
    print(f"Frame ID: {msg.header.frame_id}")
    print()
    print("加速度 (m/s²):")
    print(f"  X: {accel_x:8.4f}  Y: {accel_y:8.4f}  Z: {accel_z:8.4f}")
    print(f"  总加速度: {math.sqrt(accel_x**2 + accel_y**2 + accel_z**2):.4f} m/s²")
    print()
    print("角速度 (rad/s):")
    print(f"  X: {gyro_x:8.4f}  Y: {gyro_y:8.4f}  Z: {gyro_z:8.4f}")
    print(f"  总角速度: {math.sqrt(gyro_x**2 + gyro_y**2 + gyro_z**2):.4f} rad/s")
    print()
    print("方向 (四元数):")
    print(f"  X: {quat_x:8.4f}  Y: {quat_y:8.4f}  Z: {quat_z:8.4f}  W: {quat_w:8.4f}")
    print()
    print("欧拉角 (度):")
    print(f"  Roll:  {roll_deg:8.2f}°")
    print(f"  Pitch: {pitch_deg:8.2f}°")
    print(f"  Yaw:   {yaw_deg:8.2f}°")
    print("=" * 60)
    print()


def listener():
    """主函数：订阅IMU话题"""
    rospy.init_node('livox_imu_listener', anonymous=True)
    
    # 订阅IMU话题
    rospy.Subscriber("/livox/imu", Imu, callback_imu)
    
    print("等待IMU数据...")
    print("提示：如果收不到数据，请检查：")
    print("  1. 雷达驱动是否正常运行: roslaunch livox_ros_driver2 msg_MID360.launch")
    print("  2. 话题是否存在: rostopic list | grep imu")
    print("  3. 话题是否有数据: rostopic hz /livox/imu")
    print()
    
    rospy.spin()


if __name__ == '__main__':
    try:
        listener()
    except rospy.ROSInterruptException:
        pass

