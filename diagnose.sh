echo 'ROS_Version='$ROS_DISTRO
echo 'ROS_IP='$ROS_IP
echo 'ROS_HOSTNAME='$ROS_HOSTNAME
echo 'ROS_HOSTNAME='$ROS_MASTER_URI
echo 'BASE_TYPE='$BASE_TYPE
echo 'CAMERA_TYPE='$CAMERA_TYPE
echo 'LIDAR_TYPE='$LIDAR_TYPE
echo 'V-display:' `ls  /usr/share/X11/xorg.conf.d/|grep xorg.conf`
cd ~/catkin_ws/src/bingda_ros1_noetic && git branch && cd -
#lsusb
ifconfig |grep -B 1 inet
