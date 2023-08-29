package main
import "core:fmt"
import "core:c"
import gl "vendor:OpenGL"
import "vendor:glfw"
import glm "core:math/linalg/glsl"

PROGRAMNAME :: "Program"

GL_MAJOR_VERSION : c.int : 4;
GL_MINOR_VERSION :: 6;

running : b32 = true;
height : i32 = 720;
width : i32 = 1280;

mousePos : glm.vec2 = glm.vec2{0.0, 0.0};
mouseMovement : glm.vec2 = glm.vec2{0.0, 0.0};

main :: proc() {
	deltaTime : f32 = 0.0;
	lastFrame : f32 = 0.0;
	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR,GL_MAJOR_VERSION) 
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR,GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)

	if(glfw.Init() != 1){
		fmt.println("Failed to initialize GLFW")
		return
	}

	defer glfw.Terminate()

	window := glfw.CreateWindow(width, height, PROGRAMNAME, nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		fmt.println("Unable to create window")
		return
	}
	
	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address) 
	
	program, shader_success := gl.load_shaders("shaders/shader.vertshader", "shaders/shader.fragshader");
    defer gl.DeleteProgram(program);
	gl.UseProgram(program);   
	uniform_infos := gl.get_uniforms_from_program(program);

	vertices := []f32 {
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5,  0.5,  0.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
         0.5, -0.5, -0.5,  1.0, 1.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    };

	indices := []u32 {0, 1, 2};

	vbo, vao, ebo: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32));
	gl.EnableVertexAttribArray(0);

	gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);
	view := glm.mat4 {
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	};
	projection := glm.mat4 {
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	};

	model := glm.mat4 {
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	};

	projection = glm.mat4Perspective(0.785398, (cast(f32)width) / (cast(f32)height), 0.01, 1000.0);
	
	camera : Camera
	camera.pos = glm.vec3{0.0, 0.0, -3.0};
	camera.up = glm.vec3{0.0, 1.0, 0.0};
	camera.front = glm.vec3{0.0, 0.0, 1.0};
	camera.right = glm.vec3{1.0, 0.0, 0.0};
	camera.pitch = 45.0;
	camera.yaw = 90.0;
	camera.speed = 1.0;
	camera.sensitivity = 0.25;

	view = getCameraViewMatrix(camera);
	for (!glfw.WindowShouldClose(window) && running) {
		process_mouse(window);
		currentFrame := cast(f32)glfw.GetTime();
		deltaTime = currentFrame - lastFrame;
		lastFrame = currentFrame;
		camera = updateCamera(camera, deltaTime, mouseMovement, window);

		view = getCameraViewMatrix(camera);

		glfw.PollEvents();
		gl.ClearColor(1.0, 1.0, 1.0, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT);

		gl.UseProgram(program);   
		uniform_infos := gl.get_uniforms_from_program(program);

		gl.BindVertexArray(vao);

		gl.UniformMatrix4fv(uniform_infos["projection"].location, 1, gl.FALSE, &projection[0][0]);
		gl.UniformMatrix4fv(uniform_infos["view"].location, 1, gl.FALSE, &view[0][0]);
		gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &model[0][0]);

		gl.DrawArrays(gl.TRIANGLES, 0, 36);

		drawGrid();

		glfw.SwapBuffers((window))
	}
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