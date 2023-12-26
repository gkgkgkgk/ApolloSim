package main
import "core:fmt"
import "core:c"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"
import glm "core:math/linalg/glsl"
import "core:strings"

running : b32 = true;

mousePos : glm.vec2 = glm.vec2{0.0, 0.0};
mouseMovement : glm.vec2 = glm.vec2{0.0, 0.0};

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

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE {
		running = false
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_mouse :: proc(window: glfw.WindowHandle){
	x, y := glfw.GetCursorPos(window)
	mouseMovement = mousePos - glm.vec2{cast(f32)x, cast(f32)y}
	mousePos = glm.vec2{cast(f32)x, cast(f32)y}
}