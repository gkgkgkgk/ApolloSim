package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/rand"

calibrate :: proc() {
    fmt.println("Is this a real calibration (y) or a simulated one (n)?")
    real := readInput(os.stdin)
    
    if(strings.has_prefix(real, "y")){
        fmt.println("Please Enter Calibration Time")
    }
    else {
        generateFakeCalibrationData();
        fmt.println("Calibration data generated.")
    }

    fmt.println("Data Analyzed. Found the following materials:")

    analyzeData();
}

laserData :: struct {
    angle : f32,
    distance : f32,
    intensity : f32,
    material : string
}

angleData :: struct {
    angle: f32,
    mean: f32,
    stdev: f32,
    intensities : [dynamic]f32,
    distances : [dynamic]f32,
    meanDistance : f32,
    stdevDistance : f32
}

LightingModel :: enum {
    OrenNayar,
    CookTorrence
}

materialData :: struct {
    material : string,
    lasers : [dynamic]laserData,
    anglesData : map[f32]angleData,
    mean : f32,
    stdev : f32,
    meanDistance : f32,
    stdevDistance : f32,
    lightingModel : LightingModel
}

summarizeData :: proc(materials : map[string]materialData) {
    for material in materials {
        fmt.printf("Material: %s \n\tMean: %f\n\tStandard Deviation: %f\n\tTotal Lasers: %d\n", material, materials[material].mean, materials[material].stdev, len(materials[material].lasers))
        fmt.println(materials[material].anglesData)
    }
}

parseLaser :: proc(line : string) -> Maybe(laserData) {
    laser : laserData
    values, err := strings.split(line, ",")

    if(len(values) > 1){
        laser.distance = cast(f32)strconv.atof(values[0])
        laser.intensity = cast(f32)strconv.atof(values[1])
        laser.angle = cast(f32)strconv.atof(values[2])

        // TODO: This logic should be handled by a config file somewhere
        if(laser.angle < 180.0){
            laser.material = "metal"
        } else {
            laser.material = "concrete"
        }

        return laser;
    }
    
    return nil;
}

stdev :: proc (list : [dynamic]f32) -> f32 {
    mean : f32 = 0.0;
    sum : f32 = 0.0;
    std : f32 = 0.0;

    n := len(list);

    for i := 0; i < n; i += 1 {
        sum += list[i];
    }

    mean = sum / f32(n)

    for i := 0; i < n; i += 1 {
        std += math.pow(list[i] - mean, 2.0)
    }

    std = math.sqrt(std / f32(n))

    return std
}

analyzeData :: proc () {
    data, success := getEntireFile("./data.txt").?

    if(!success){
        fmt.println("Could not read LIDAR data file.")
        return
    }

    lines := strings.split(data, "\n")

    materials := make(map[string]materialData);
    
    // for evert laser, sort them into a material. create the material if it doesnt exist
    for line in lines{
        laser, success := parseLaser(line).?

        if(success && !(laser.material in materials)) {
            mat : materialData
            mat.material = laser.material
            mat.lasers = {laser}
            materials[laser.material] = mat
        } else if(success){
            mat := materials[laser.material]
            lasers := materials[laser.material].lasers
            append(&lasers, laser)
            mat.lasers = lasers
            materials[laser.material] = mat
        }        
    }

    // for every material, run calculations
    for material in materials {
        m := materials[material]
        total : f32 = 0.0;
        intensities : [dynamic]f32;
        totalDistance : f32 = 0.0;
        distances : [dynamic]f32;

        // first, get total intensities of the material, to calculate overall mean and stdev
        for laser in m.lasers {
            // get intensities for every laser
            total += laser.intensity;
            append(&intensities, laser.intensity);

            totalDistance += laser.distance;
            append(&distances, laser.distance);

            // also, sort the lasers into angle structs, so that each angle has its own data
            if(!(laser.angle in m.anglesData)) {
                angle : angleData;
                angle.angle = laser.angle;
                angle.intensities = {laser.intensity}
                angle.distances = {laser.distance}
                m.anglesData[laser.angle] = angle;
            } else {
                angle := m.anglesData[laser.angle]
                
                intensities := m.anglesData[laser.angle].intensities
                append(&intensities, laser.intensity)
                angle.intensities = intensities

                distances := m.anglesData[laser.angle].distances
                append(&distances, laser.distance)
                angle.distances = distances

                m.anglesData[laser.angle] = angle
            }

        }

        // now for every angle struct, run the analysis
        for angle in m.anglesData {
            data := m.anglesData[angle]
            total : f32 = 0.0
            totalDistance : f32 = 0.0

            for i in data.intensities {
                total += i;
            }

            for i in data.distances {
                totalDistance += i;
            }

            data.mean = total / f32(len(data.intensities))
            data.stdev = stdev(data.intensities)

            data.meanDistance = totalDistance / f32(len(data.distances))
            data.stdevDistance = stdev(data.distances)

            m.anglesData[angle] = data
        }

        // run final analysis on the overall material
        m.mean = total / f32(len(m.lasers));
        m.stdev = stdev(intensities)

        m.meanDistance = totalDistance / f32(len(m.lasers));
        m.stdevDistance = stdev(distances)

        materials[material] = m
    }

    summarizeData(materials);
}

generateFakeCalibrationData :: proc() {
    f := createBlankFile("./data.txt");

    angularRes := 0.225;

    for j := 0; j < 5; j += 1{
        for i := 0; i < 1600; i += 1 {
            buf := [128]byte{}
            buf2 := [128]byte{}
            buf3 := [128]byte{}
            floatStr := strconv.ftoa(buf[:], angularRes * cast(f64)i, 'g', 6, 64)
            intensityStr := strconv.ftoa(buf2[:], rand.float64(), 'g', 6, 64)
            distanceStr := strconv.ftoa(buf3[:], rand.float64(), 'g', 6, 64)

            str := strings.join({distanceStr, intensityStr, floatStr}, ",");
            appendLine(f, str);
        }
    }

}