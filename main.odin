package main
import "core:fmt"
import "core:c"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"
import glm "core:math/linalg/glsl"
import "core:strings"

main :: proc() {
	args := os.args;
	calibrationData : CalibrationData;

	if len(args) > 1 && args[1] == "calibrate" {
		configFile :string = ""

		if len(args) > 2 {
			configFile = args[2]
			fmt.println("Calibrating on config file: ", configFile)
		}

		calibrationData = calibrate(configFile);
		fmt.println("Launch Simulation? (y or n)");
		launch := readInput(os.stdin);

		if(!strings.has_prefix(launch, "y")){
			return;
		}
	}

	simEngine : SimEngine;
	simEngineSuccess : bool;

	if len(args) > 2 && args[1] == "viewer" {
		calibrationData = calibrate("");
		fmt.printf("Viewing Calibration file %s\n", args[2]);
		
		gfxEngine, gfxEngineSuccess := initializeGFXEngine().?;
		
		if !gfxEngineSuccess {
			fmt.println("Failed to initialize Graphics Engine.")
			return
		}

		simEngine, simEngineSuccess = initializeSimEngine(calibrationData, true).?;

		if !simEngineSuccess {
			fmt.println("Failed to initialize Viewer Simulation Engine.")
			return
		}

		loopGFXEngineViewer(gfxEngine, simEngine);
	} else {
		gfxEngine, gfxEngineSuccess := initializeGFXEngine().?;
		
		if !gfxEngineSuccess {
			fmt.println("Failed to initialize Graphics Engine.")
			return
		}

		simEngine, simEngineSuccess = initializeSimEngine(calibrationData, false).?;
		

		if !simEngineSuccess {
			fmt.println("Failed to initialize Simulation Engine.")
			return
		}

		loopGFXEngine(gfxEngine, simEngine);
	}
}