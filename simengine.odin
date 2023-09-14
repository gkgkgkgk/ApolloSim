package main
import "core:fmt"
import gl "vendor:OpenGL"
import "core:os"
import "core:strings"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShader : u32
}

initializeSimEngine :: proc () -> Maybe(SimEngine) {
    engine : SimEngine
    engine.steps = 0
    engine.sensor = initializeSensor();

    computeShaderSource, computeShaderError := os.read_entire_file("./shaders/sensor.computeshader")    
    if !computeShaderError {
        fmt.println("Failed to initialize compute shader for the simulation engine.");
        return nil
    }
    computeShaderSourceString : cstring = cstring(raw_data(computeShaderSource));

    computeShader := gl.CreateShader(gl.COMPUTE_SHADER);
    gl.ShaderSource(computeShader, 1, &computeShaderSourceString, nil);
    gl.CompileShader(computeShader);

    fmt.println("Successfully initialized simulation engine.");

    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine{
    engine := engine
    // fmt.printf("Performed step %d to gather %f points. \n", engine.steps, engine.sensor.sampleFrequency / engine.sensor.scanFrequency)

    // At this point, the calculation should be handed off to a compute shader for parellel processing.


    engine.steps = engine.steps + 1
    return engine
}