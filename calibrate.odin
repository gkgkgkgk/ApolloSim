package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

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

    analyzeData();
}

laserData :: struct {
    angle : f32,
    distance : f32,
    intensity : f32,
    material : string
}

materialData :: struct {
    material : string,
    lasers : [dynamic]laserData
}

parseLaser :: proc(line : string) -> Maybe(laserData) {
    laser : laserData
    values, err := strings.split(line, ",")

    if(len(values) > 1){
        laser.distance = cast(f32)strconv.atof(values[0])
        laser.intensity = cast(f32)strconv.atof(values[1])
        laser.angle = cast(f32)strconv.atof(values[2])
        laser.material = "metal"

        return laser;
    }
    
    return nil;
}

analyzeData :: proc () {
    data, success := getEntireFile("./data.txt").?

    if(!success){
        fmt.println("Could not read LIDAR data file.")
        return
    }

    lines := strings.split(data, "\n")

    materials := make(map[string]materialData);
    
    for line in lines{
        laser, success := parseLaser(line).?

        if(success && !(laser.material in materials)) {
            mat : materialData
            mat.material = laser.material
            mat.lasers = {laser}
            materials[laser.material] = mat
        } else {
            mat := materials[laser.material]
            lasers := materials[laser.material].lasers
            append(&lasers, laser)
            mat.lasers = lasers
            materials[laser.material] = mat
        }
        
    }

    fmt.println(materials)
}

generateFakeCalibrationData :: proc() {
    f := createBlankFile("./data.txt");

    angularRes := 0.225;

    for i := 0; i < 1600; i += 1 {
        buf := [128]byte{}
        floatStr := strconv.ftoa(buf[:], angularRes * cast(f64)i, 'g', 6, 64)

        str := strings.join({"1.0", "0.5", floatStr}, ",");
        appendLine(f, str);
    }

}