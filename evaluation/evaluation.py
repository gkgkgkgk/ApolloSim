import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
from colour import Color
import math
# SET PGF FOR EXPORTING LATEX DATA
matplotlib.use("pgf")
matplotlib.rcParams.update({
    "pgf.texsystem": "pdflatex",
    'font.family': 'serif',
    'text.usetex': True,
    'pgf.rcfonts': False,
})

def darken_hex(hex_value, percentage):
    if not hex_value.startswith('#') or len(hex_value) not in [7, 4]:
        raise ValueError("Provided hex_value is not a valid hex color code.")

    hex_value = hex_value.lstrip('#')
    if len(hex_value) == 3:
        hex_value = ''.join([2 * char for char in hex_value])
    rgb = tuple(int(hex_value[i:i+2], 16) for i in (0, 2, 4))
    rgb_darker = tuple(int((1 - percentage) * value) for value in rgb)
    hex_darker = '#' + ''.join(f'{value:02x}' for value in rgb_darker)

    return hex_darker

def drop_rate(series):
    return (series == 0).mean()

# PROCESS WOOD DATA
def process_sim_data(filepath):
    f = open(filepath, "r")
    data = (f.read())
    f.close()

    objects = []

    for line in data.strip().split("\n"):
        parts = line.split(",")
        if(len(parts) > 1):
            angle = parts[0]
            intensity = parts[1]
            distance = parts[2]


            item = {
                "angle": math.radians(float(angle)),
                "intensity": float(intensity),
                "distance": float(distance),
            }

            objects.append(item)


    df = pd.DataFrame(objects)

    grouped = df.groupby('angle').agg(
        mean_intensity=pd.NamedAgg(column='intensity', aggfunc='mean'),
        stdev_intensity=pd.NamedAgg(column='intensity', aggfunc='std'),
        drop_rate=pd.NamedAgg(column='intensity', aggfunc=drop_rate),
        stdev_distance=pd.NamedAgg(column='distance', aggfunc='std')
    ).reset_index().sort_values(by='angle', ascending=True)

    items_array = grouped.to_dict('records')
    return items_array

sim_objects = {"wood":process_sim_data("./wood_data.txt"), "wall":process_sim_data("./wall_data.txt"), "metal":process_sim_data("./metal_data.txt"), "metal2":process_sim_data("./metal2_data.txt"), "acrylic":process_sim_data("./acrylic_data.txt")}

# PROCESS REAL CALIBRATION DATA

f = open("./real_data.txt", "r")
real_data = (f.read())
f.close()

objects = {"wood":[], "wall":[], "metal":[], "metal2":[], "acrylic":[]}
alt_names = {"wood":"Plywood", "wall":"Epoxy", "metal":"Brushed Aluminum", "metal2":"Shiny Aluminum", "acrylic":"Frosted Glass"}
colors = {"wood":"#FFA500", "wall":"#8a8a8a", "metal":"#8d92c2", "metal2":"#d1d1d1", "acrylic":"#72BCD4"}

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
        "mean_intensity": float(mean) / 47.0,
        "stdev_intensity": float(stdev) / 47.0,
        "stdev_distance": float(distancestdev),
        "drop_rate": float(droprate),
    }

    objects[material].append(item)


# GENERATE MEAN GRAPH
def mean_graph():
    fig, axs = plt.subplots(5, figsize=(8, 10))
    fig.suptitle('Mean Intensity by Angle', fontsize=16)

    for i, material in enumerate(objects):
        angles = [item['angle'] for item in objects[material]]
        max_angle = max(angles)
        sim_angles_unfiltered = [item['angle'] for item in sim_objects[material]]
        sim_angles = [angle for angle in sim_angles_unfiltered if angle <= max_angle]

        mean_intensities = [item['mean_intensity'] for item in objects[material]]
        mean_sim_intensities = [item['mean_intensity'] for item in sim_objects[material]][:len(sim_angles)]
        axs[i].plot(sim_angles, mean_sim_intensities, marker='s', label="Simulation", color=darken_hex(colors[material], 0.5))
        axs[i].plot(angles, mean_intensities, marker='o', label="Calibrated", color=colors[material])
        axs[i].set_title(alt_names[material])
        axs[i].set_ylim(0, 1.0)
        axs[i].legend()


    fig.supylabel('Mean Intensity')
    fig.supxlabel('Lidar Beam Angle (radians)')

    plt.tight_layout()
    plt.savefig('mean_plot.pgf')

def std_graph():
    fig, axs = plt.subplots(5, figsize=(8, 10))
    fig.suptitle('Standard Deviation of Intensity by Angle', fontsize=16)

    for i, material in enumerate(objects):
        angles = [item['angle'] for item in objects[material]]
        max_angle = max(angles)
        sim_angles_unfiltered = [item['angle'] for item in sim_objects[material]]
        sim_angles = [angle for angle in sim_angles_unfiltered if angle <= max_angle]

        mean_intensities = [item['stdev_intensity'] for item in objects[material]]
        mean_sim_intensities = [item['stdev_intensity'] for item in sim_objects[material]][:len(sim_angles)]
        axs[i].plot(sim_angles, mean_sim_intensities, marker='s', label="Simulation", color=darken_hex(colors[material], 0.5))
        axs[i].plot(angles, mean_intensities, marker='o', label="Calibrated", color=colors[material])
        axs[i].set_title(alt_names[material])
        axs[i].set_ylim(0, 1.0)
        axs[i].legend()


    fig.supylabel('Standard Deviation of Intensity')
    fig.supxlabel('Lidar Beam Angle (radians)')

    plt.tight_layout()
    plt.savefig('stdev_plot.pgf')

def droprate_graph():
    fig, axs = plt.subplots(5, figsize=(8, 10))
    fig.suptitle('Raydrop Rate by Angle', fontsize=16)

    for i, material in enumerate(objects):
        angles = [item['angle'] for item in objects[material]]
        max_angle = max(angles)
        sim_angles_unfiltered = [item['angle'] for item in sim_objects[material]]
        sim_angles = [angle for angle in sim_angles_unfiltered if angle <= max_angle]

        dr = [item['drop_rate'] for item in objects[material]]
        dr_sim = [item['drop_rate'] for item in sim_objects[material]][:len(sim_angles)]
        axs[i].plot(sim_angles, dr_sim, marker='s', label="Simulation", color=darken_hex(colors[material], 0.5))
        axs[i].plot(angles, dr, marker='o', label="Calibrated", color=colors[material])
        axs[i].set_title(alt_names[material])
        axs[i].set_ylim(0, 1.0)
        axs[i].legend()


    fig.supylabel('Drop Rate')
    fig.supxlabel('Lidar Beam Angle (radians)')

    plt.tight_layout()
    plt.savefig('droprate_plot.pgf')

def distance_graph():
    fig, axs = plt.subplots(5, figsize=(8, 10))
    fig.suptitle('Standard Deviation of Distance by Angle', fontsize=16)

    for i, material in enumerate(objects):
        angles = [item['angle'] for item in objects[material]]
        max_angle = max(angles)
        sim_angles_unfiltered = [item['angle'] for item in sim_objects[material]]
        sim_angles = [angle for angle in sim_angles_unfiltered if angle <= max_angle]

        dr = [item['stdev_distance'] for item in objects[material]]
        dr_sim = [item['stdev_distance'] for item in sim_objects[material]][:len(sim_angles)]
        axs[i].plot(sim_angles, dr_sim, marker='s', label="Simulation", color=darken_hex(colors[material], 0.5))
        axs[i].plot(angles, dr, marker='o', label="Calibrated", color=colors[material])
        axs[i].set_title(alt_names[material])
        axs[i].set_ylim(0, 0.05)
        axs[i].legend()


    fig.supylabel('Standard Deviation of Distance')
    fig.supxlabel('Lidar Beam Angle (radians)')

    plt.tight_layout()
    plt.savefig('distance_plot.pgf')
    
mean_graph()
std_graph()
droprate_graph()
distance_graph()
# plt.show()
