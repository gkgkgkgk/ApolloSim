package main
import "core:fmt"
import "core:os"

calibrate :: proc() {
    fmt.println("Is this a real calibration (y) or a simulated one (n)?")
    real := readInput(os.stdin)
    
    if(real == "y"){
        fmt.println("Please Enter Clibration Time")
        readInput(os.stdin)
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
	str := string(buf[:n])

	return str;
}