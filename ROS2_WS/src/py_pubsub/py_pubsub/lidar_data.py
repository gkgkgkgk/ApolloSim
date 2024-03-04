import rclpy
from rclpy.node import Node
import pygame
import math
from sensor_msgs.msg import LaserScan

pygame.init()

screen_width = 640
screen_height = 480
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption('lidar')

class LidarSubscriber(Node):

    def __init__(self):
        super().__init__('lidar_subscriber')
        self.subscription = self.create_subscription(
            LaserScan,
            '/scan',
            self.listener_callback,
            10)

        filename = input("Enter your material name: ")
        self.width = float(input("Enter your material width: "))
        self.distance = float(input("Enter your material distance: "))


        f = open(filename+"_data.txt", "w")
        self.data = f

        def __del__(self):
            self.f.close()

    def listener_callback(self, msg):
        self.LaserToString(msg)

    def LaserToString(self, laser):
        print(laser.header.stamp.sec)

        start_angle = laser.angle_min
        end_angle = laser.angle_max
        angle_increment = laser.angle_increment
        range_min = laser.range_min
        range_max = laser.range_max
        string = "[Timestamp:{}.{};start_angle:{};end_angle:{};angle_increment:{};range_min:{};range_max:{};ranges:{};intensities:{}]".format(
            laser.header.stamp.sec,
            laser.header.stamp.nanosec,
            start_angle,
            end_angle,
            angle_increment,
            range_min,
            range_max,
            laser.ranges,
            laser.intensities)
        
        currentAngle = start_angle
        for a in range(len(laser.ranges)):
            # self.data.write(",".join((str(laser.ranges[a]), str(laser.intensities[a]), str(currentAngle))))
            # self.data.write("\n")
            currentAngle += angle_increment

        screen.fill((0,0,0))
        angle = start_angle
        spread = 50.0

        pygame.draw.line(screen, (255, 0, 0), (screen_width // 2, 0), (screen_width // 2, screen_height), 2)
        pygame.draw.line(screen, (255, 0, 0), (0, screen_height // 2), (screen_width, screen_height // 2), 2)

        max_angle = math.atan2((self.width / 2.0 ), self.distance)

        pygame.draw.line(screen, (0, 255, 0), (screen_width//2, screen_height // 2), (screen_width//2 + spread * self.distance, screen_height//2 + spread * self.width / 2.0), 2)
        pygame.draw.line(screen, (0, 255, 0), (screen_width//2, screen_height // 2), (screen_width//2 + spread * self.distance, screen_height//2 - spread * self.width / 2.0), 2)

        for distance in laser.ranges:
            if not math.isinf(distance):            
                x = screen_width - (int(math.cos(angle) * distance * spread) + screen_width // 2)
                y = int(math.sin(angle) * distance * spread) + screen_height // 2
                
                if (angle > 0 and angle > math.pi - max_angle) or (angle < 0 and angle < -math.pi + max_angle):
                    pygame.draw.circle(screen, (255, 255, 255), (x,y), 5)
                else:
                    pygame.draw.circle(screen, (100, 100, 100), (x,y), 5)

            angle += angle_increment
        
        pygame.display.flip()

        return string


def main(args=None):
    rclpy.init(args=args)

    lidar_subscriber = LidarSubscriber()

    rclpy.spin(lidar_subscriber)

    lidar_subscriber.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
