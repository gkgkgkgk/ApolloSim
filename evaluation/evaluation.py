import matplotlib.pyplot as plt
import pandas as pd

f = open("./real_data.txt", "r")
real_data = (f.read())
f.close()

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

plt.figure(figsize=(10, 6))

for material, items in objects.items():
    angles = [item['angle'] for item in items]
    stdev_intensities = [item['stdev_intensity'] for item in items]
    plt.plot(angles, stdev_intensities, marker='o', label=material)

plt.title('Std dev Intensity by Angle for Different Materials')
plt.xlabel('Angle (degrees)')
plt.ylabel('Std dev Intensity')
plt.legend()

pd.set_option('display.max_rows', None)  # or set a large number instead of None

f = open("./wood_data.txt", "r")
wood_data = (f.read())
f.close()

wood_objects = []

for line in wood_data.strip().split("\n"):
    parts = line.split(",")
    angle = parts[0]
    intensity = parts[1]
    distance = parts[2]

    item = {
        "material": "wood",
        "angle": float(angle),
        "intensity": float(intensity),
        "distance": float(distance),
    }

    wood_objects.append(item)

f = open("./wall_data.txt", "r")
wall_data = (f.read())
f.close()

wall_objects = []

for line in wall_data.strip().split("\n"):
    parts = line.split(",")
    angle = parts[0]
    intensity = parts[1]
    distance = parts[2]

    item = {
        "material": "wall",
        "angle": float(angle),
        "intensity": float(intensity),
        "distance": float(distance),
    }

    wall_objects.append(item)


df = pd.DataFrame(wood_objects + wall_objects)
print(df)

plt.figure(figsize=(10, 6))

for material, items in objects.items():
    angles = df[df['material'] == material]['angle'].unique()
    mean_intensities = df[df['material'] == material].groupby(['material', 'angle'])['intensity'].mean()

    plt.plot(angles, mean_intensities, marker='o', label=material)

plt.title('Mean Intensity by Angle for Different Materials')
plt.xlabel('Angle (degrees)')
plt.ylabel('Mean Intensity')
plt.legend()

plt.figure(figsize=(10, 6))


plt.show()