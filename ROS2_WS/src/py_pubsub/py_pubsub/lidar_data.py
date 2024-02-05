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
        self.data.write(str(msg))
        self.data.write('\n')


def main(args=None):
    rclpy.init(args=args)

    lidar_subscriber = LidarSubscriber()

    rclpy.spin(lidar_subscriber)

    lidar_subscriber.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
