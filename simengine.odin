package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "core:math"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShaderProgram : u32,
    scene : [dynamic]Geometry,
    complexScene : [dynamic]Geometry,
    complexScene32 : []Geometry32,
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

    status : i32;
    gl.GetShaderiv(computeShader, gl.COMPILE_STATUS, &status);

    if(status != 1){
        fmt.println("Failed to compile the compute shader for the simulation engine.");
        return nil;
    }

    computeShaderProgram := gl.CreateProgram();
    gl.AttachShader(computeShaderProgram, computeShader);
    gl.LinkProgram(computeShaderProgram)

    engine.computeShaderProgram = computeShaderProgram;

    cube := createCube();
    cube.model = identityModel * glm.mat4Translate({1.0, 0.0, 0.0});
    append(&engine.scene, cube)

    cube2 := createCube();
    cube2.model = identityModel * glm.mat4Translate({0.0, 0.0, 5.0});
    append(&engine.scene, cube2)

    stopSign := customGeometry("./models/stopsign.obj")
    stopSign.model = identityModel * glm.mat4Translate({2.5, 0.0, 2.5});
    append(&engine.complexScene, stopSign)

    complexScene32 := make([]Geometry32, len(engine.scene));
    for i := 0; i < len(engine.complexScene); i += 1 {
        cg : Geometry32;

        cg.vertices = engine.complexScene[i].vertices
        indices : [dynamic]int;

        for j := 0; j < len(engine.complexScene[i].indices); j += 1 {
            append(&indices, cast(int)engine.complexScene[i].indices[j]);
        }

        cg.indices = indices;
        cg.model = engine.complexScene[i].model;
        cg.gType = 100;

        complexScene32[i] = cg;
    }

    engine.complexScene32 = complexScene32;

    fmt.println("Successfully initialized simulation engine.");
    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine {
    engine := engine

    sg := make([]SimpleGeometry, len(engine.scene));

    for i := 0; i < len(engine.scene); i+=1 {
        sgTemp : SimpleGeometry
        sgTemp.model = engine.scene[i].model
        sgTemp.gType = engine.scene[i].gType
        sg[i] = sgTemp
    }

    complexSceneSize := 0
    for i := 0; i < len(engine.complexScene32); i += 1 {
        complexSceneSize += size_of(f32) * len(engine.complexScene32[i].vertices)
        complexSceneSize += size_of(int) * len(engine.complexScene32[i].indices)
        complexSceneSize += size_of(glm.mat4)
        complexSceneSize += size_of(int)
    }

    directions := make([]glm.vec4, 16)

    for i := 0; i < 16; i+=1 {
        angle : f32 = ((2 * math.PI)/16.0) * cast(f32)i
        directions[i] = glm.vec4{math.cos(angle), 0.0, math.sin(angle), 0.0}
    }

    outputData := make([]glm.vec4, engine.sensor.packetSize);

    inputBuffer, inputBuffer2, inputBuffer3, outputBuffer: u32;
    gl.GenBuffers(1, &inputBuffer); defer gl.DeleteBuffers(1, &inputBuffer);
    gl.GenBuffers(1, &inputBuffer2); defer gl.DeleteBuffers(1, &inputBuffer2);
    gl.GenBuffers(1, &inputBuffer3); defer gl.DeleteBuffers(1, &inputBuffer3);
	gl.GenBuffers(1, &outputBuffer); defer gl.DeleteBuffers(1, &outputBuffer);

    // Load in scene geometry
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, inputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(sg) * size_of(SimpleGeometry), &sg[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, inputBuffer2);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(glm.vec4) * len(engine.sensor.directions), &engine.sensor.directions[0], gl.STATIC_DRAW);

    // There are definitely issues here with how the custom geoemtry is being loaded in... maybe pad the vertices to a fixed size? maybe struct padding?
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, inputBuffer3);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER,complexSceneSize, &engine.complexScene32[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 3, outputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0], gl.STATIC_DRAW);

    gl.UseProgram(engine.computeShaderProgram);
    gl.DispatchCompute(1, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0])

    cube := engine.scene[0]
    cube.model = identityModel * glm.mat4Translate({2 * math.cos(cast(f32)engine.steps * 0.05), 0.0, 2 * math.sin(cast(f32)engine.steps * 0.05)});
    engine.scene[0] = cube

    engine.outputData = outputData
    engine.steps = engine.steps + 1
    return engine
}