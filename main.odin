package main
import "core:fmt"
import "core:c"
import gl "vendor:OpenGL"
import "vendor:glfw"
import glm "core:math/linalg/glsl"

running : b32 = true;

mousePos : glm.vec2 = glm.vec2{0.0, 0.0};
mouseMovement : glm.vec2 = glm.vec2{0.0, 0.0};

main :: proc() {

	gfxEngine, gfxEngineSuccess := initializeGFXEngine().?;

	if !gfxEngineSuccess {
		fmt.println("Failed to initialize Graphics Engine.")
		return
	}

	loopGFXEngine(gfxEngine);
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