import numpy as np

file_path = './rawdata/test2_sim.txt'
output_path = './data/test2sim_mean.txt'

# Dictionary to hold sum of intensities and count for each angle
intensity_sum_by_angle = {}
distance_sum_by_angle = {}

count_by_angle = {}

angles = {}

with open(file_path, 'r') as file:
    for line in file:
        distance, intensity, angle = line.strip().split(',')
        intensity = float(intensity)
        angle = float(angle)

        if distance == "inf":
            distance = 0.0
        
        distance = float(distance)

        if angle in angles:
            angles[angle]["intensity"].append(intensity)
            angles[angle]["distance"].append(distance)
        else:
            a = {}
            a["intensity"] = [intensity]
            a["distance"] = [distance]
            angles[angle] = a

with open(output_path, 'w') as output_file:
    for angle in angles:
        print(angle, angles[angle])
        angles[angle]["intensity"] = np.nanmean(angles[angle]["intensity"])
        angles[angle]["distance"] = np.nanmean(angles[angle]["distance"])
        output_file.write(f"{angles[angle]['distance']},{angles[angle]['intensity']},{angle}\n")
        print(angles[angle])




# for angle in sorted(average_intensity_by_angle):
#     print(f"Angle: {angle:.2f}, Average Intensity: {average_intensity_by_angle[angle]:.2f}")