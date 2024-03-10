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
		configFile :string = ""
		materialName : string = ""

		if len(args) > 2 {
			configFile = args[2]
			fmt.println("Calibrating on config file: ", configFile)
		}

		if len(args) > 3 {
			materialName = args[3]
		}

		calibrationData = calibrate(configFile);

		fmt.println(materialName);
		for matInput in calibrationData.materialInputs {
			if matInput.materialName == materialName {
				calibrationData.materialLength = matInput.width * 2.0;
				calibrationData.distance = matInput.distance;
				break;
			}
		}
		

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
		configFile : string = "./data.config"

		if len(args) > 1 {
			configFile = args[1]
		}

		gfxEngine, gfxEngineSuccess := initializeGFXEngine().?;
		
		if !gfxEngineSuccess {
			fmt.println("Failed to initialize Graphics Engine.")
			return
		}

		calibrationData = calibrate(configFile);

		simEngine, simEngineSuccess = initializeSimEngine(calibrationData, false).?;
		

		if !simEngineSuccess {
			fmt.println("Failed to initialize Simulation Engine.")
			return
		}

		loopGFXEngine(gfxEngine, simEngine);
	}
}