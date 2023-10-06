package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShaderProgram : u32,
    scene : [dynamic]Geometry,
    outputData : []glm.vec4
}

initializeSimEngine :: proc () -> Maybe(SimEngine) {
    engine : SimEngine
    engine.steps = 0
    engine.sensor = initializeSensor();

    computeShaderSource, computeShaderError := os.read_entire_file("./shaders/sensor.computeshader.glsl")    
    if !computeShaderError {
        fmt.println("Failed to initialize compute shader for the simulation engine.");
        return nil
    }
    computeShaderSourceString := cstring(raw_data(computeShaderSource));

    computeShader := gl.CreateShader(gl.COMPUTE_SHADER);
    gl.ShaderSource(computeShader, 1, &computeShaderSourceString, nil);
    gl.CompileShader(computeShader);

    computeShaderProgram := gl.CreateProgram();
    gl.AttachShader(computeShaderProgram, computeShader);
    gl.LinkProgram(computeShaderProgram)

    engine.computeShaderProgram = computeShaderProgram;

    cube := createCube();
    cube.model = identityModel * glm.mat4Translate({1.0, 0.0, 0.0});
    append(&engine.scene, cube)

    fmt.println("Successfully initialized simulation engine.");
    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine {
    engine := engine
    // fmt.printf("Performed step %d to gather %f points. \n", engine.steps, engine.sensor.sampleFrequency / engine.sensor.scanFrequency)
    // At this point, the calculation should be handed off to a compute shader for parellel processing.
    outputData := make([]glm.vec4, 3);
    sg := make([]SimpleGeometry, len(engine.scene));

    for i := 0; i < len(engine.scene); i+=1 {
        sgTemp : SimpleGeometry
        sgTemp.model = engine.scene[i].model
        sgTemp.gType = engine.scene[i].gType
        sg[i] = sgTemp
    }

    inputBuffer, outputBuffer: u32;
    gl.GenBuffers(1, &inputBuffer); defer gl.DeleteBuffers(1, &inputBuffer);
	gl.GenBuffers(1, &outputBuffer); defer gl.DeleteBuffers(1, &outputBuffer);

    // Load in scene geometry
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, inputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(SimpleGeometry), &sg[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, outputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, 3 * size_of(glm.vec4), &outputData[0], gl.STATIC_DRAW);

    gl.UseProgram(engine.computeShaderProgram);
    gl.DispatchCompute(16, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, 3 * size_of(glm.vec4), &outputData[0])

    engine.outputData = outputData
    engine.steps = engine.steps + 1
    return engine
}