package main
import "core:fmt"
import "core:os"
import "core:strings"

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

    for i := 0; i < 1600; i += 1 {
        str := "hi :)";
        appendLine(f, str);
    }

}