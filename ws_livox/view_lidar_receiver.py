#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
接收端查看雷达数据脚本
适用于接收端无法编译 livox_ros_driver2 的情况
支持两种消息格式：CustomMsg 和 PointCloud2
"""

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy

# 尝试导入 CustomMsg，如果失败则使用 PointCloud2
try:
    from livox_ros_driver2.msg import CustomMsg
    USE_CUSTOM_MSG = True
    print("✓ 成功导入 CustomMsg 格式")
except ImportError:
    try:
        from sensor_msgs.msg import PointCloud2
        USE_CUSTOM_MSG = False
        print("⚠ 无法导入 CustomMsg，使用 PointCloud2 格式")
    except ImportError:
        print("❌ 错误: 无法导入任何消息类型")
        exit(1)


class LidarSubscriber(Node):
    def __init__(self):
        super().__init__('lidar_subscriber')
        
        # 设置 QoS 配置（雷达数据通常使用 BEST_EFFORT）
        qos_profile = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            history=HistoryPolicy.KEEP_LAST,
            depth=10
        )
        
        if USE_CUSTOM_MSG:
            self.subscription = self.create_subscription(
                CustomMsg,
                '/livox/lidar',
                self.custom_msg_callback,
                qos_profile
            )
            self.get_logger().info('订阅 CustomMsg 格式: /livox/lidar')
        else:
            self.subscription = self.create_subscription(
                PointCloud2,
                '/livox/lidar',
                self.pointcloud2_callback,
                qos_profile
            )
            self.get_logger().info('订阅 PointCloud2 格式: /livox/lidar')
        
        self.get_logger().info('等待雷达数据...')
        self.count = 0
    
    def custom_msg_callback(self, msg):
        """CustomMsg 格式回调"""
        self.count += 1
        print(f"\n{'='*60}")
        print(f"消息 #{self.count}")
        print(f"{'='*60}")
        print(f"点数量: {msg.point_num}")
        print(f"时间戳: {msg.timebase}")
        print(f"Lidar ID: {msg.lidar_id}")
        
        if len(msg.points) > 0:
            print(f"\n前5个点的信息:")
            for i, point in enumerate(msg.points[:5]):
                print(f"  点 {i+1:2d}: "
                      f"x={point.x:8.3f}  "
                      f"y={point.y:8.3f}  "
                      f"z={point.z:8.3f}  "
                      f"reflectivity={point.reflectivity:3d}  "
                      f"tag={point.tag}  "
                      f"line={point.line}")
        print(f"{'='*60}")
    
    def pointcloud2_callback(self, msg):
        """PointCloud2 格式回调"""
        self.count += 1
        print(f"\n{'='*60}")
        print(f"消息 #{self.count}")
        print(f"{'='*60}")
        print(f"宽度: {msg.width}")
        print(f"高度: {msg.height}")
        print(f"点数量: {msg.width * msg.height}")
        print(f"时间戳: {msg.header.stamp.sec}.{msg.header.stamp.nanosec}")
        print(f"Frame ID: {msg.header.frame_id}")
        print(f"点云字段数: {len(msg.fields)}")
        print("字段列表:")
        for field in msg.fields:
            print(f"  - {field.name}: 偏移={field.offset}, 数据类型={field.datatype}, 数量={field.count}")
        print(f"{'='*60}")


def main(args=None):
    rclpy.init(args=args)
    
    try:
        subscriber = LidarSubscriber()
        rclpy.spin(subscriber)
    except KeyboardInterrupt:
        print("\n\n程序被用户中断")
    except Exception as e:
        print(f"\n错误: {e}")
    finally:
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()

