package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "core:math"
import "core:math/rand"
import "core:time"

SimEngine :: struct {
    steps : int,
    sensor : Sensor,
    computeShaderProgram : u32,
    scene : [dynamic]Geometry,
    complexScene : [dynamic]Geometry,
    complexScene32 : []Geometry32,
    outputData : []glm.vec4,
    inputBuffer, inputBuffer2, inputBuffer3, inputBuffer4, inputBuffer5, outputBuffer, inputBuffer6, inputBuffer7: u32
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
    cube.material = createMaterial(0.1, 0.75, 0.25, 0.5);
    cube = addTexture(cube, "./textures/concrete.jpg");
    append(&engine.scene, cube);

    cube2 := createCube();
    cube2.model = identityModel * glm.mat4Translate({0.0, 0.0, 5.0});
    cube2.material = createMaterial(0.9, 0.75, 0.25, 0.000001);
    append(&engine.scene, cube2)

    stopSign := customGeometry("./models/stopsignscale.obj")
    stopSign.model = identityModel * glm.mat4Translate({2.5, 0, 2.5});
    append(&engine.complexScene, stopSign)

    complexScene32 := make([]Geometry32, len(engine.scene));
    for i := 0; i < len(engine.complexScene); i += 1 {
        cg : Geometry32;

        cg.vertices = engine.complexScene[i].vertices
        indices : [dynamic]i32;

        for j := 0; j < len(engine.complexScene[i].indices); j += 1 {
            append(&indices, cast(i32)engine.complexScene[i].indices[j]);
        }

        cg.indices = indices;
        cg.model = engine.complexScene[i].model;
        cg.gType = 100;

        complexScene32[i] = cg;
    }

    engine.complexScene32 = complexScene32;
    inputBuffer, inputBuffer2, inputBuffer3, inputBuffer4, inputBuffer5, outputBuffer, inputBuffer6, inputBuffer7: u32

    gl.GenBuffers(1, &inputBuffer);
    gl.GenBuffers(1, &inputBuffer2);
    gl.GenBuffers(1, &inputBuffer3);
    gl.GenBuffers(1, &inputBuffer4);
    gl.GenBuffers(1, &inputBuffer5);
	gl.GenBuffers(1, &outputBuffer);
	gl.GenBuffers(1, &inputBuffer6);
	gl.GenBuffers(1, &inputBuffer7);

    engine.inputBuffer = inputBuffer;
    engine.inputBuffer2 = inputBuffer2;
    engine.inputBuffer3 = inputBuffer3;
    engine.inputBuffer4 = inputBuffer4;
    engine.inputBuffer5 = inputBuffer5;
    engine.outputBuffer = outputBuffer;
    engine.inputBuffer6 = inputBuffer6;
    engine.inputBuffer7 = inputBuffer7;

    fmt.println("Successfully initialized simulation engine.");
    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine {
    engine := engine

    sg := make([]SimpleGeometry, len(engine.scene));
    materials := make([]Material, len(engine.scene));

    for i := 0; i < len(engine.scene); i+=1 {
        sgTemp : SimpleGeometry
        sgTemp.model = engine.scene[i].model
        sgTemp.gType = cast(i32)engine.scene[i].gType

        materials[i] = engine.scene[i].material;
        sgTemp.material = cast(i32)i;

        sg[i] = sgTemp
    }

    complexSceneSize := 0
    for i := 0; i < len(engine.complexScene32); i += 1 {
        complexSceneSize += size_of(f32) * len(engine.complexScene32[i].vertices)
        complexSceneSize += size_of(int) * len(engine.complexScene32[i].indices)
        complexSceneSize += size_of(glm.mat4)
        complexSceneSize += size_of(int)
    }

    outputData := make([]glm.vec4, engine.sensor.packetSize);

    my_rand := rand.create(1)
    seeds := make([]f32, len(engine.sensor.directions))
    for i := 0; i < len(seeds); i += 1 {
        seeds[i] = rand.float32(&my_rand);
    }

    // Load in scene geometry
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, engine.inputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(sg) * size_of(SimpleGeometry), &sg[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, engine.inputBuffer2);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(glm.vec4) * len(engine.sensor.directions), &engine.sensor.directions[0], gl.STATIC_DRAW);

    // There are definitely issues here with how the custom geoemtry is being loaded in... maybe pad the vertices to a fixed size? maybe struct padding?
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, engine.inputBuffer3);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER,complexSceneSize, &engine.complexScene32[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 3, engine.inputBuffer4);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(f32) * len(engine.complexScene32[0].vertices), &(engine.complexScene32[0].vertices)[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 4, engine.inputBuffer5);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(i32) * len(engine.complexScene32[0].indices), &(engine.complexScene32[0].indices)[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 5, engine.outputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 6, engine.inputBuffer6);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(materials) * size_of(Material), &materials[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 7, engine.inputBuffer7);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(seeds) * size_of(f32), &seeds[0], gl.STATIC_DRAW);

    timeUniformLocation := gl.GetUniformLocation(engine.computeShaderProgram, "u_time");

    gl.UseProgram(engine.computeShaderProgram);
    gl.Uniform1f(timeUniformLocation, cast(f32)(time.to_unix_nanoseconds(time.now()) % 100000));
    gl.DispatchCompute(1, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, engine.outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0])

    cube := engine.scene[0]
    cube.model = identityModel * glm.mat4Translate({2 * math.cos(cast(f32)engine.steps * 0.0005), 0.0, 2 * math.sin(cast(f32)engine.steps * 0.0005)});
    engine.scene[0] = cube

    engine.outputData = outputData
    engine.steps = engine.steps + 1
    return engine
}