package main;
import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "core:math"
import "core:math/rand"
import "core:time"
import "core:fmt"

GPUData :: struct {
    angleDeg: f32,
    materialId: i32,
    meanIntensity: f32,
    meanDistance: f32,
    stdevIntensity: f32,
    stdevDistance: f32,
    dropRate: f32
}

generateGPUData :: proc(engine : SimEngine, benchmarkLength : f32, benchmarkDistance : f32) -> [dynamic]GPUData {
    maxAngle := math.to_degrees(math.atan((benchmarkLength / 2.0) / benchmarkDistance));

    gpudata : [dynamic]GPUData;
    i := 0;

    for materialInput in engine.calibrationData.materialInputs {
        material := materialInput.materialName;

        for angle in engine.calibrationData.materials[material].anglesData {
            angleData := angle;
            gd : GPUData;
            gd.angleDeg = math.to_degrees((angleData.angle));
            gd.materialId = engine.calibrationData.materials[material].materialId;
            // TODO: Right now this works only for a 2d lidar...
            gd.meanIntensity = angleData.mean;
            gd.stdevIntensity = angleData.stdev;
            gd.meanDistance = angleData.meanDistance;
            gd.stdevDistance = angleData.stdevDistance;
            gd.dropRate = angleData.dropRate;

            append(&gpudata, gd);
            i += 1;
        }
    }

    // printMaterialGPUData(-1, gpudata);

    return gpudata;
} 

printMaterialGPUData :: proc (materialId : i32, gpudata : [dynamic]GPUData) {
    for data in gpudata {
        if (data.materialId == materialId || materialId < 0) {
            fmt.println(data);
        }
    }
}

sendDataToGPU :: proc(engine : SimEngine) -> []glm.vec4{
    sg := make([]SimpleGeometry, len(engine.scene));
    materials := make([]Material, len(engine.scene));

    for i := 0; i < len(engine.scene); i+=1 {
        sgTemp : SimpleGeometry
        sgTemp.model = engine.scene[i].model
        sgTemp.gType = cast(i32)engine.scene[i].gType

        sgTemp.material = cast(i32) engine.scene[i].material;

        sg[i] = sgTemp
    }

    complexSceneSize := 0
    for i := 0; i < len(engine.complexScene32); i += 1 {
        complexSceneSize += size_of(f32) * len(engine.complexScene32[i].vertices)
        complexSceneSize += size_of(int) * len(engine.complexScene32[i].indices)
        complexSceneSize += size_of(glm.mat4)
        complexSceneSize += size_of(int)
    }

    gpuDataSize := len(engine.gpuData) * (size_of(f32) * 6) + size_of(i32)

    outputData := make([]glm.vec4, engine.sensor.packetSize);
    outputData2 := make([]glm.vec4, engine.sensor.packetSize);

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
    if len(engine.complexScene32) > 0 {
        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 2, engine.inputBuffer3);
        gl.BufferData(gl.SHADER_STORAGE_BUFFER,complexSceneSize, &engine.complexScene32[0], gl.STATIC_DRAW);

        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 3, engine.inputBuffer4);
        gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(f32) * len(engine.complexScene32[0].vertices), &(engine.complexScene32[0].vertices)[0], gl.STATIC_DRAW);

        gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 4, engine.inputBuffer5);
        gl.BufferData(gl.SHADER_STORAGE_BUFFER, size_of(i32) * len(engine.complexScene32[0].indices), &(engine.complexScene32[0].indices)[0], gl.STATIC_DRAW);
    }

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 5, engine.outputBuffer);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0], gl.STATIC_DRAW);
    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 9, engine.outputBuffer2);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, engine.sensor.packetSize * size_of(glm.vec4), &outputData2[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 6, engine.inputBuffer6);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(materials) * size_of(Material), &materials[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 7, engine.inputBuffer7);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, len(seeds) * size_of(f32), &seeds[0], gl.STATIC_DRAW);

    gl.BindBufferBase(gl.SHADER_STORAGE_BUFFER, 8, engine.inputBuffer8);
    gl.BufferData(gl.SHADER_STORAGE_BUFFER, gpuDataSize, &engine.gpuData[0], gl.STATIC_DRAW);

    timeUniformLocation := gl.GetUniformLocation(engine.computeShaderProgram, "u_time");

    gl.UseProgram(engine.computeShaderProgram);
    gl.Uniform1f(timeUniformLocation, cast(f32)(time.to_unix_nanoseconds(time.now()) % 100000));
    gl.DispatchCompute(1, 1, 1);
    gl.MemoryBarrier(gl.ALL_BARRIER_BITS);

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, engine.outputBuffer);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, engine.sensor.packetSize * size_of(glm.vec4), &outputData[0])

    gl.BindBuffer(gl.SHADER_STORAGE_BUFFER, engine.outputBuffer2);
    gl.GetBufferSubData(gl.SHADER_STORAGE_BUFFER, 0, engine.sensor.packetSize * size_of(glm.vec4), &outputData2[0])

    return outputData;
}