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
    calibrationData : CalibrationData,
    gpuData : [dynamic]GPUData,
    inputBuffer, inputBuffer2, inputBuffer3, inputBuffer4, inputBuffer5, outputBuffer, inputBuffer6, inputBuffer7, inputBuffer8, outputBuffer2: u32
}

initializeSimEngine :: proc (calibrationData : CalibrationData, viewer : bool) -> Maybe(SimEngine) {
    engine : SimEngine
    engine.steps = 0
    engine.sensor = initializeSensor();
    engine.calibrationData = calibrationData;

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

    if !viewer {
        // initialize scene
        cube := createCube();
        cube.model = identityModel * glm.mat4Translate({0.0, 0.0, 35.0}) * glm.mat4Scale(glm.vec3{50.1, 50.1, 50.1});
        cube.material = 4;
        append(&engine.scene, cube);

        // cube2 := createCube();
        // cube2.model = identityModel * glm.mat4Translate({0.0, 0.0, 5.0});
        // cube2.material = 1;
        // append(&engine.scene, cube2)

        stopSign := customGeometry("./models/stopsignscale.obj")
        stopSign.model = identityModel * glm.mat4Translate({25, 0, 25});
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
    } else {
        for i := -3; i < 4; i += 1 {
	        cube := createCube();
            cube.model = identityModel * glm.mat4Translate({calibrationData.distance + (0.5), 0.0, f32(i)});
            cube.material = 0;
            append(&engine.scene, cube);
        }

        complexScene32 := make([]Geometry32, 0);
    }

    // initialize compute shader buffers (TODO: get rid of these PLEASE)
    inputBuffer, inputBuffer2, inputBuffer3, inputBuffer4, inputBuffer5, outputBuffer, inputBuffer6, inputBuffer7, inputBuffer8, outputBuffer2: u32
    gl.GenBuffers(1, &inputBuffer);
    gl.GenBuffers(1, &inputBuffer2);
    gl.GenBuffers(1, &inputBuffer3);
    gl.GenBuffers(1, &inputBuffer4);
    gl.GenBuffers(1, &inputBuffer5);
	gl.GenBuffers(1, &outputBuffer);
	gl.GenBuffers(1, &inputBuffer6);
	gl.GenBuffers(1, &inputBuffer8);
	gl.GenBuffers(1, &outputBuffer2);

    engine.inputBuffer = inputBuffer;
    engine.inputBuffer2 = inputBuffer2;
    engine.inputBuffer3 = inputBuffer3;
    engine.inputBuffer4 = inputBuffer4;
    engine.inputBuffer5 = inputBuffer5;
    engine.outputBuffer = outputBuffer;
    engine.inputBuffer6 = inputBuffer6;
    engine.inputBuffer7 = inputBuffer7;
    engine.inputBuffer8 = inputBuffer8;
    engine.outputBuffer2 = outputBuffer2;

    engine.gpuData = generateGPUData(engine, calibrationData.materialLength, calibrationData.distance);
    fmt.println("Successfully initialized simulation engine.");
    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine {
    engine := engine

    outputData := sendDataToGPU(engine);
    
    // cube := engine.scene[0]
    // cube.model = identityModel * glm.mat4Translate({2 * math.cos(cast(f32)engine.steps * 0.005), 0.0, 2 * math.sin(cast(f32)engine.steps * 0.005)});
    // engine.scene[0] = cube

    // cube2 := engine.scene[1]
    // cube2.model = identityModel * glm.mat4Translate({4 * math.sin(cast(f32)engine.steps * 0.005), 0.0, 4 * math.cos(cast(f32)engine.steps * 0.005)});
    // engine.scene[1] = cube2

    engine.outputData = outputData
    engine.steps = engine.steps + 1
    return engine
}

stepSimEngineViewer :: proc (engine : SimEngine, material : int) -> SimEngine {
    engine := engine

    l := 0

    for data in engine.gpuData {
        if(int(data.materialId) == material){
            l += 1;
        }
    }

    outputData := make([]glm.vec4, l * 2);

    i := 0;

    for data in engine.gpuData {
        if int(data.materialId) == material{
            x := math.cos(math.to_radians(data.angleDeg));
            y := math.tan(math.to_radians(data.angleDeg));
            outputData[i] = glm.vec4{engine.calibrationData.distance, 0.0, y, data.meanIntensity};
            outputData[i + 1] = glm.vec4{engine.calibrationData.distance, 0.0, -y, data.meanIntensity};
            i += 2;
        }
    }

    engine.outputData = outputData
    engine.steps = engine.steps + 1
    return engine
}