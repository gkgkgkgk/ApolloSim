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
        fmt.println("Calibration data generated.")
    }
    
}

readInput :: proc(input: os.Handle) -> string {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	if err < 0 {
		// Handle error
		return ""
	}

	str := strings.clone_from_bytes(buf[:n]);

	return strings.trim(str, "\n");
}