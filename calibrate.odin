package main
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

calibrate :: proc() {
    fmt.println("Is this a real calibration (y) or a simulated one (n)?")
    real := readInput(os.stdin)
    
    if(strings.has_prefix(real, "y")){
        fmt.println("Please Enter Clibration Time")
    }
    else {
        generateFakeCalibrationData();
        fmt.println("Calibration data generated.")
    }
    
}

generateFakeCalibrationData :: proc() {
    f := createBlankFile("./data.txt");

    angularRes := 0.225;

    for i := 0; i < 1600; i += 1 {
        buf := [128]byte{}
        floatStr := strconv.ftoa(buf[:], angularRes * cast(f64)i, 'g', 6, 64)

        str := strings.join({"1.0", "0.5", floatStr}, ",");
        fmt.println(str)
        appendLine(f, str);
    }

}