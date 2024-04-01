import struct
import math
import numpy as np
import sys

# Constants
BRDF_SAMPLING_RES_THETA_H = 90
BRDF_SAMPLING_RES_THETA_D = 90
BRDF_SAMPLING_RES_PHI_D = 360

RED_SCALE = 1.0 / 1500.0
GREEN_SCALE = 1.15 / 1500.0
BLUE_SCALE = 1.66 / 1500.0

def read_brdf(filename):
    with open(filename, 'rb') as f:
        dims = struct.unpack('iii', f.read(12))
        n = dims[0] * dims[1] * dims[2]
        if n != BRDF_SAMPLING_RES_THETA_H * BRDF_SAMPLING_RES_THETA_D * BRDF_SAMPLING_RES_PHI_D // 2:
            raise ValueError("Dimensions do not match")

        brdf = np.fromfile(f, dtype=np.double, count=3 * n)
        return brdf.reshape((n, 3), order='F')

def process_brdf(brdf):
    print(brdf)
    n = 16
    for i in range(n):
        theta_in = i * math.pi / n
        for j in range(4 * n):
            phi_in = j * 2 * math.pi / (4 * n)
            for k in range(n):
                theta_out = k * math.pi / n
                for l in range(4 * n):
                    phi_out = l * 2 * math.pi / (4 * n)

if __name__ == '__main__':
    brdf_data = read_brdf('C:/Users/Gavri Kepets/Downloads/BRDF/brdfs/alum-bronze.binary')
    process_brdf(brdf_data)