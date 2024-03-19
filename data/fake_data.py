import math

start = -3.1241393089294434
end = 3.1415928034111857

step = abs((start - end) / (719.0))

angle = start

filepath = "./fake_data.txt"

with open(filepath, 'w') as file:
    pass

roughness = 0.5

with open(filepath, 'a') as file:
    for i in range(720):
        distance = "inf"
        intensity = 0.0

        if angle < -math.pi + math.radians(45.0) or angle > math.pi - math.radians(45.0):
            intensity = math.cos(math.pi - angle)
            distance = abs(0.5 / math.cos(angle))

        file.write(str(distance) + "," + str(intensity) + "," + str(angle) + "\n")
        angle += step