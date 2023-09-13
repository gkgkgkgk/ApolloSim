package main
import "core:fmt"
import gl "vendor:OpenGL"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShader : u32
}

initializeSimEngine :: proc () -> SimEngine {
    engine : SimEngine
    engine.steps = 0
    engine.sensor = initializeSensor();

    engine.computeShader = gl.CreateShader(gl.COMPUTE_SHADER);
    gl.ShaderSource(engine.computeShader, 1, )

    program, shader_success := gl.load_shaders("shaders/shader.vertshader", "shaders/shader.fragshader");

    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine{
    engine := engine
    // fmt.printf("Performed step %d to gather %f points. \n", engine.steps, engine.sensor.sampleFrequency / engine.sensor.scanFrequency)

    // At this point, the calculation should be handed off to a compute shader for parellel processing.


    engine.steps = engine.steps + 1
    return engine
}