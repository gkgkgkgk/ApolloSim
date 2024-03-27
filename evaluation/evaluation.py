import matplotlib.pyplot as plt

f = open("./real_data.txt", "r")
real_data = (f.read())

objects = {}

for line in real_data.strip().split("\n"):
    parts = line.split(",")
    material = parts[0]
    angle = parts[1]
    mean = parts[2]
    stdev = parts[3]
    distancestdev = parts[4]
    droprate = parts[5]

    item = {
        "angle": float(angle),
        "mean_intensity": float(mean),
        "stdev_intensity": float(stdev),
        "stdev_distance": float(distancestdev),
        "drop_rate": float(droprate),
    }

    if material in objects:
        objects[material].append(item)
    else:
        objects[material] = [item]


plt.figure(figsize=(10, 6))

for material, items in objects.items():
    angles = [item['angle'] for item in items]
    mean_intensities = [item['mean_intensity'] for item in items]
    plt.plot(angles, mean_intensities, marker='o', label=material)

plt.title('Mean Intensity by Angle for Different Materials')
plt.xlabel('Angle (degrees)')
plt.ylabel('Mean Intensity')
plt.legend()

plt.show()

plt.figure(figsize=(10, 6))

for material, items in objects.items():
    angles = [item['angle'] for item in items]
    stdev_intensities = [item['stdev_intensity'] for item in items]
    plt.plot(angles, stdev_intensities, marker='o', label=material)

plt.title('Std dev Intensity by Angle for Different Materials')
plt.xlabel('Angle (degrees)')
plt.ylabel('Std dev Intensity')
plt.legend()

plt.show()