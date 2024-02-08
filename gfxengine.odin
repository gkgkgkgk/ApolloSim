package main

import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "vendor:glfw"
import "core:math"
import "core:c"
import "core:fmt"
import "core:thread"

PROGRAMNAME :: "Program"

GL_MAJOR_VERSION : c.int : 4;
GL_MINOR_VERSION :: 6;

height : i32 = 720;
width : i32 = 1280;

identityModel := glm.mat4 {
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
};

GFXEngine :: struct {
    window : glfw.WindowHandle,
    camera: Camera,
    shaders: [dynamic]u32,
    projection : glm.mat4,
    model : glm.mat4,
    deltaTime : f32,
	lastFrame : f32
}

initializeGFXEngine :: proc() -> Maybe(GFXEngine) {
    engine : GFXEngine

    glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR,GL_MAJOR_VERSION) 
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR,GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)


    when ODIN_OS == .Windows {
        if(glfw.Init() != 1.0){
            fmt.println("Failed to initialize GLFW")
            return nil
	    }
    } else when ODIN_OS == .Linux {
        if(glfw.Init() != true){
            fmt.println("Failed to initialize GLFW")
            return nil
	    }
    }
    

    engine.window = glfw.CreateWindow(width, height, PROGRAMNAME, nil, nil)

    if engine.window == nil {
		fmt.println("Unable to create window")
		return nil
	}

    glfw.MakeContextCurrent(engine.window)
	glfw.SwapInterval(1)
	glfw.SetKeyCallback(engine.window, key_callback)
	glfw.SetFramebufferSizeCallback(engine.window, size_callback)
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address) 

    camera : Camera
	camera.pos = glm.vec3{0.0, 1.0, -1.0};
	camera.up = glm.vec3{0.0, 1.0, 0.0};
	camera.front = glm.vec3{0.0, 0.0, 1.0};
	camera.right = glm.vec3{1.0, 0.0, 0.0};
	camera.pitch = 45.0;
	camera.yaw = 0.0;
	camera.speed = 5.0;
	camera.sensitivity = 0.15;

    engine.camera = camera;

    engine.shaders = initializeShaders(engine);

    gl.Enable(gl.DEPTH_TEST);
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
	gl.Enable(gl.BLEND)

    engine.projection = glm.mat4Perspective(0.785398, (cast(f32)width) / (cast(f32)height), 0.01, 1000.0);

    engine.deltaTime = 0.0
    engine.lastFrame = 0.0

    fmt.println("Successfully initialized graphics engine.");
    return engine
}

loopGFXEngine :: proc(engine: GFXEngine, simEngine: SimEngine) {
    defer glfw.Terminate()
	defer glfw.DestroyWindow(engine.window)
    defer destroyShaders(engine)

    engine := engine
    simEngine := simEngine
    view : glm.mat4

    for (!glfw.WindowShouldClose(engine.window) && running) {
		process_mouse(engine.window);
		currentFrame := cast(f32)glfw.GetTime();
		engine.deltaTime = currentFrame - engine.lastFrame;
		engine.lastFrame = currentFrame;
		engine.camera = updateCamera(engine.camera, engine.deltaTime, mouseMovement, engine.window);

		view = getCameraViewMatrix(engine.camera);

		glfw.PollEvents();
		gl.ClearColor(1.0, 1.0, 1.0, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT);
		gl.Clear(gl.DEPTH_BUFFER_BIT);

        gl.UseProgram(engine.shaders[0]);   
		uniform_infos := gl.get_uniforms_from_program(engine.shaders[0]);

		gl.UniformMatrix4fv(uniform_infos["projection"].location, 1, gl.FALSE, &engine.projection[0][0]);
		gl.UniformMatrix4fv(uniform_infos["view"].location, 1, gl.FALSE, &view[0][0]);
		gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &(simEngine.sensor.geometry.model)[0][0]);
		drawGeometryWithIndices(simEngine.sensor.geometry);

        for i := 0; i < len(simEngine.scene); i+= 1 {
            gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &(simEngine.scene[i].model)[0][0]);
		    drawGeometryWithIndices(simEngine.scene[i]);
        }

        for i := 0; i < len(simEngine.complexScene); i+= 1 {
            gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &(simEngine.complexScene[i].model)[0][0]);
		    drawGeometryWithIndices(simEngine.complexScene[i]);
        }

		gl.UseProgram(engine.shaders[1])
        uniform_infos = gl.get_uniforms_from_program(engine.shaders[1]);
		gl.UniformMatrix4fv(uniform_infos["projection"].location, 1, gl.FALSE, &engine.projection[0][0]);
		gl.UniformMatrix4fv(uniform_infos["view"].location, 1, gl.FALSE, &view[0][0]);
		gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &identityModel[0][0]);
		drawGrid(100);

        gl.UseProgram(engine.shaders[2])
        uniform_infos = gl.get_uniforms_from_program(engine.shaders[2]);
		gl.UniformMatrix4fv(uniform_infos["projection"].location, 1, gl.FALSE, &engine.projection[0][0]);
		gl.UniformMatrix4fv(uniform_infos["view"].location, 1, gl.FALSE, &view[0][0]);
		gl.UniformMatrix4fv(uniform_infos["model"].location, 1, gl.FALSE, &identityModel[0][0]);
		drawLasers(simEngine);

		glfw.SwapBuffers((engine.window))

        simEngine = stepSimEngine(simEngine);
	}
}

initializeShaders :: proc(engine: GFXEngine) -> [dynamic]u32{
    shaders : [dynamic]u32
    program, shader_success := gl.load_shaders("shaders/shader.vertshader.glsl", "shaders/shader.fragshader.glsl");
    append(&shaders, program)

    grid_program, grid_shader_success := gl.load_shaders("shaders/grid.vertshader.glsl", "shaders/grid.fragshader.glsl");
    append(&shaders, grid_program)

    laser_program, laser_shader_success := gl.load_shaders("shaders/laser.vertshader.glsl", "shaders/laser.fragshader.glsl");
    append(&shaders, laser_program)

    return shaders
}

destroyShaders :: proc (engine: GFXEngine) {
    gl.DeleteProgram(engine.shaders[0]);
    gl.DeleteProgram(engine.shaders[1]);
    gl.DeleteProgram(engine.shaders[2]);
}

drawGrid :: proc($gridSize: int) {
    gl.LineWidth(1.0);
    vertices : [6 * 2 * (gridSize+ 1)]f32;

    for i := 0; i < gridSize + 1; i += 1 {
        index := i * 12
        lineLength := (cast(f32)gridSize + 1) * 0.5;
        offset := cast(f32) i - lineLength + 0.5;
        // add vertical line
        vertices[index] = offset;
        vertices[index + 1] = 0;
        vertices[index + 2] = -lineLength+ 0.5;

        vertices[index + 3] = offset;
        vertices[index + 4] = 0;
        vertices[index + 5] = lineLength- 0.5;

        // add horizontal line
        vertices[index + 6] = -lineLength + 0.5;
        vertices[index + 7] = 0;
        vertices[index + 8] = offset;

        vertices[index + 9] = lineLength - 0.5;
        vertices[index + 10] = 0;
        vertices[index + 11] = offset;
    }

    vbo, vao: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);

    gl.DrawArrays(gl.LINES, 0, (cast(i32)gridSize + 1) * 4);
}

drawLasers:: proc(engine: SimEngine) {
    lasers := engine.outputData;
    laserCount : int = len(lasers);

    if(laserCount == 0){
        return;
    }

    vertices : [dynamic]f32;

    for i := 0; i < laserCount; i += 1 {
        append(&vertices, 0)
        append(&vertices, 0)
        append(&vertices, 0)
        append(&vertices, lasers[i].w)

        append(&vertices, lasers[i].x)
        append(&vertices, lasers[i].y)
        append(&vertices, lasers[i].z)
        append(&vertices, lasers[i].w)
    }

    vbo, vao: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

	gl.BindVertexArray(vao)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);
    gl.LineWidth(3.0);

    gl.DrawArrays(gl.LINES, 0, cast(i32)laserCount * 2);
}