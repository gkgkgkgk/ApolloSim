import rclpy
from rclpy.node import Node

from sensor_msgs.msg import LaserScan

class LidarSubscriber(Node):

    def __init__(self):
        super().__init__('lidar_subscriber')
        self.subscription = self.create_subscription(
            LaserScan,
            '/scan',
            self.listener_callback,
            10)
        self.subscription
        f = open("data.txt", "w")
        self.data = f

        def __del__(self):
            self.f.close()

    def listener_callback(self, msg):
        self.data.write(self.LaserToString(msg))
        self.data.write("\n\n")

    def LaserToString(self, laser):
        print(laser.header.stamp.sec)

        start_angle = laser.angle_min
        end_angle = laser.angle_max
        angle_increment = laser.angle_increment
        range_min = laser.range_min
        range_max = laser.range_max
        string = "Timestamp: {}.{}\nstart_angle: {}\nend_angle: {}\nangle_increment: {}\nrange_min: {}\nrange_max: {}\nranges: {}\nintensities: {}".format(
            laser.header.stamp.sec,
            laser.header.stamp.nanosec,
            start_angle,
            end_angle,
            angle_increment,
            range_min,
            range_max,
            laser.ranges,
            laser.intensities)

        return string


def main(args=None):
    rclpy.init(args=args)

    lidar_subscriber = LidarSubscriber()

    rclpy.spin(lidar_subscriber)

    lidar_subscriber.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
