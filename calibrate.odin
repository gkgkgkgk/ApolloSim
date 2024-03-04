package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/rand"

// calibration data for each material
CalibrationData :: struct {
    materials : map[string]MaterialData,
    distance : f32,
    materialLength : f32
};

// calibration data for one material
MaterialData :: struct {
    material : string,
    lasers : [dynamic]laserData,
    anglesData : map[f32]angleData,
    mean : f32,
    stdev : f32,
    meanDistance : f32,
    stdevDistance : f32,
    lightingModel : LightingModel
}

// struct for a single laser beam
laserData :: struct {
    angle : f32,
    distance : f32,
    intensity : f32,
    material : string,
    dropped : bool
}

// struct for a certain angle
angleData :: struct {
    angle: f32,
    mean: f32,
    stdev: f32,
    intensities : [dynamic]f32,
    distances : [dynamic]f32,
    meanDistance : f32,
    stdevDistance : f32,
    dropRate: f32
}

// the lighting model of the material
LightingModel :: enum {
    OrenNayar,
    CookTorrence
}

MaterialInput :: struct {
    materialName : string,
    filePath : string,
    distance : f32,
    width : f32
}

calibrate :: proc(configFile : string) -> CalibrationData {
    cd : CalibrationData;
    real : string;
    matInputs : [dynamic]MaterialInput;

    if(configFile == ""){
        fmt.println("Is this a real calibration (y) or a simulated one (n)?")
        real := readInput(os.stdin)
    } else {
        real = "y"
    }

    if(strings.has_prefix(real, "y")){
        newfile : string;
        if(configFile == ""){
            fmt.println("Generate a new config file (y) or use a previous one (n)?")
            newfile = readInput(os.stdin)
        } else {
            newfile = "n";
        }

        if strings.has_prefix(newfile, "y"){
            for {
                fmt.println("Please enter the name of the material.")
                matName := readInput(os.stdin)

                fmt.printf("Please provide the path to the %s data file.\n", matName)
                file := readInput(os.stdin)

                fmt.println("Please enter the distance (m) from the sensor to the benchmark material.")
                distance := cast(f32)strconv.atof(readInput(os.stdin))

                fmt.println("Please enter the width (m) of the benchmark material.")
                width := cast(f32)strconv.atof(readInput(os.stdin))

                mat : MaterialInput;
                mat.materialName = matName;
                mat.filePath = file;
                mat.distance = distance;
                mat.width = width;
                append(&matInputs, mat);

                fmt.println("Saved material: ", mat)

                fmt.println("Are there more materials? (y or n)")
                more := readInput(os.stdin)

                if !strings.has_prefix(more, "y"){
                    config := createBlankFile("./data.config")

                    for mat in matInputs {
                        buf := [128]byte{}
                        buf2 := [128]byte{}

                        distanceStr := strconv.ftoa(buf[:], f64(mat.distance), 'g', 6, 64)
                        widthStr := strconv.ftoa(buf2[:], f64(mat.width), 'g', 6, 64)

                        str := strings.join({mat.materialName, mat.filePath, distanceStr, widthStr}, ",");
                        appendLine(config, str)
                    }
                    fmt.println("Generating Config File...")
                    break
                }
            }
        } else {
            c : string
            if configFile == "" {
                fmt.println("What is the path to the config file?")
                c := readInput(os.stdin)
            } else {
                c = configFile
            }
            
            config := getEntireFile(c).?
            lines := strings.split(config, "\n")

            for line in lines {
                l := strings.split(line, ",")

                mat : MaterialInput;
                mat.materialName = l[0];
                mat.filePath = l[1];
                mat.distance = cast(f32)strconv.atof(l[2]);
                mat.width = cast(f32)strconv.atof(l[3]);

                append(&matInputs, mat);
            }

            
        }

        fmt.println("Gathered the following materials: ", matInputs);
    }
    else {
        generateFakeCalibrationData();
        fmt.println("Calibration data generated.")
    }

    fmt.println("Data Analyzed. Found the following materials:");
    data, success := analyzeData(matInputs).?;

    if !success {
        fmt.println("Unable to find data file.");
        return cd;
    }

    cd.materials = data;
    cd.distance = 1.0;
    cd.materialLength = 2.0;

    return cd;
}

summarizeData :: proc(materials : map[string]MaterialData) {
    for material in materials {
        fmt.printf("Material: %s \n\tMean: %f\n\tStandard Deviation: %f\n\tTotal Lasers: %d\n", material, materials[material].mean, materials[material].stdev, len(materials[material].lasers))
    }
}

parseLaser :: proc(line : string, material: string) -> Maybe(laserData) {
    laser : laserData
    values, err := strings.split(line, ",")

    if(len(values) > 1){
        if values[0] == "inf"{
            laser.distance = -1.0
            laser.dropped = true
        } else {
            laser.distance = cast(f32)strconv.atof(values[0])
            laser.dropped = false
        }

        laser.intensity = cast(f32)strconv.atof(values[1])
        laser.angle = cast(f32)strconv.atof(values[2])
        laser.material = material

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

analyzeData :: proc (matInputs: [dynamic]MaterialInput) -> Maybe(map[string]MaterialData){
    materials := make(map[string]MaterialData);

    for mat in matInputs {
        data, success := getEntireFile(mat.filePath).?

        if(!success){
            fmt.println("Could not read LIDAR data file for ", )
            return nil
        }

        lines := strings.split(data, "\n")

        // for every laser, sort them into a material. create the material if it doesnt exist
        for line in lines{
            laser, success := parseLaser(line, mat.materialName).?
            maxAngle := math.atan2((mat.width / 2.0 ), mat.distance)

            // first, check if this laser is a valid angle
            if (laser.angle > 0 && laser.angle > math.PI - maxAngle) || (laser.angle < 0 && laser.angle < -math.PI + maxAngle){
                if(success && !(laser.material in materials)) {
                    mat : MaterialData
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
        }
    }

    // for every material, run calculations
    // for material in materials {
    //     m := materials[material]
    //     total : f32 = 0.0;
    //     intensities : [dynamic]f32;
    //     totalDistance : f32 = 0.0;
    //     distances : [dynamic]f32;

    //     // first, get total intensities of the material, to calculate overall mean and stdev
    //     for laser in m.lasers {
    //         // get intensities for every laser
    //         total += laser.intensity;
    //         append(&intensities, laser.intensity);

    //         totalDistance += laser.distance;
    //         append(&distances, laser.distance);

    //         // also, sort the lasers into angle structs, so that each angle has its own data
    //         if(!(laser.angle in m.anglesData)) {
    //             angle : angleData;
    //             angle.angle = laser.angle;
    //             angle.intensities = {laser.intensity}
    //             angle.distances = {laser.distance}
    //             m.anglesData[laser.angle] = angle;
    //         } else {
    //             angle := m.anglesData[laser.angle]
                
    //             intensities := m.anglesData[laser.angle].intensities
    //             append(&intensities, laser.intensity)
    //             angle.intensities = intensities

    //             distances := m.anglesData[laser.angle].distances
    //             append(&distances, laser.distance)
    //             angle.distances = distances

    //             m.anglesData[laser.angle] = angle
    //         }

    //     }

    //     // now for every angle struct, run the analysis
    //     for angle in m.anglesData {
    //         data := m.anglesData[angle]
    //         total : f32 = 0.0
    //         totalDistance : f32 = 0.0

    //         for i in data.intensities {
    //             total += i;
    //         }

    //         for i in data.distances {
    //             totalDistance += i;
    //         }

    //         data.mean = total / f32(len(data.intensities))
    //         data.stdev = stdev(data.intensities)

    //         data.meanDistance = totalDistance / f32(len(data.distances))
    //         data.stdevDistance = stdev(data.distances)

    //         m.anglesData[angle] = data
    //     }

    //     // run final analysis on the overall material
    //     m.mean = total / f32(len(m.lasers));
    //     m.stdev = stdev(intensities)

    //     m.meanDistance = totalDistance / f32(len(m.lasers));
    //     m.stdevDistance = stdev(distances)

    //     materials[material] = m
    // }

    summarizeData(materials);
    return materials;
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

    os.close(f);
}