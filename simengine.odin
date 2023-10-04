package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShaderProgram : u32
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

    fmt.println("Successfully initialized simulation engine.");
    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine {
    engine := engine
    // fmt.printf("Performed step %d to gather %f points. \n", engine.steps, engine.sensor.sampleFrequency / engine.sensor.scanFrequency)
    // At this point, the calculation should be handed off to a compute shader for parellel processing.

    inputData :=  [3]i32{1, 2, 3};
    outputData :=  make([]i32, 3);

    inputBuffer, outputBuffer: u32;
    gl.GenBuffers(1, &inputBuffer); defer gl.DeleteBuffers(1, &inputBuffer);
	gl.GenBuffers(1, &outputBuffer); defer gl.DeleteBuffers(1, &outputBuffer);
    
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, inputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, 3 * size_of(i32), &inputData[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, outputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, 3 * size_of(i32), &outputData[0], gl.STATIC_DRAW);

    gl.UseProgram(engine.computeShaderProgram);
    gl.DispatchCompute(3, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, 3 * size_of(i32), &outputData[0])

    fmt.println(inputData, outputData);

    engine.steps = engine.steps + 1
    return engine
}