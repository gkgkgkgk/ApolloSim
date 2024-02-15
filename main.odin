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

	if len(args) > 1 && args[1] == "calibrate" {
		calibrate();
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

	simEngine, simEngineSuccess := initializeSimEngine().?;

	if !simEngineSuccess {
		fmt.println("Failed to initialize Simulation Engine.")
		return
	}

	loopGFXEngine(gfxEngine, simEngine);
}