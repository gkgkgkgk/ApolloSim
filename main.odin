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
		calibrationData := calibrate();
		fmt.println("Launch Simulation? (y or n)");
		launch := readInput(os.stdin);

		if(!strings.has_prefix(launch, "y")){
			return;
		}
	}

	gfxEngine, gfxEngineSuccess := initializeGFXEngine().?;

	if !gfxEngineSuccess {
		fmt.println("Failed to initialize Graphics Engine.")
		return
	}

	simEngine, simEngineSuccess := initializeSimEngine(calibrationData).?;

	if !simEngineSuccess {
		fmt.println("Failed to initialize Simulation Engine.")
		return
	}

	loopGFXEngine(gfxEngine, simEngine);
}