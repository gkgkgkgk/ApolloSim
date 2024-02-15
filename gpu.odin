package main;
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "core:math/rand"
import "core:time"
import "core:fmt"

GPUData :: struct {
    angle: glm.vec4,
    materialId: int,
    meanIntensity: f32,
    meanDistance: f32,
    stdevIntensity: f32,
    stdevDistance: f32,
    dropRate: f32
}

// TODO: make sure this is only done ONCE.
generateGPUData :: proc(engine : SimEngine) -> []GPUData {
    gpudata := make([]GPUData, engine.sensor.packetSize);
    i := 0;

    for material in engine.calibrationData.materials {
        for angle in engine.calibrationData.materials[material].anglesData {
            angleData := engine.calibrationData.materials[material].anglesData[angle];
            gd : GPUData;
            gd.angle = angleData.angle;
            gpudata[i] = gd;
            i += 1;
        }
    }

    return gpudata;
} 

sendDataToGPU :: proc(engine : SimEngine) -> []glm.vec4{
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

    gpudata := generateGPUData(engine);

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

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 8, engine.inputBuffer8);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(gpudata) * size_of(GPUData), &gpudata[0], gl.STATIC_DRAW);

    timeUniformLocation := gl.GetUniformLocation(engine.computeShaderProgram, "u_time");

    gl.UseProgram(engine.computeShaderProgram);
    gl.Uniform1f(timeUniformLocation, cast(f32)(time.to_unix_nanoseconds(time.now()) % 100000));
    gl.DispatchCompute(1, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, engine.outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0])

    return outputData;
}