package main
import glm "core:math/linalg/glsl"
import "core:math"
import "core:fmt"

Sensor :: struct {
    sensorType: SensorType,
    dataDimensions: DataDimensions,
    scanFrequency: f32,
    sampleFrequency: f32,
    angularRange: f32,
    workingRange: [2]f32,
    geometry : Geometry,
    directions: []glm.vec4,
    packetSize: int
}

DataDimensions :: enum {
    TwoD,
    ThreeD
}

SensorType :: enum {
    Stationary
}

// For testing purposes, this function returns the specs for the RPLiDAR S3 at 10Hz scan frequency
initializeSensor :: proc () -> Sensor {
    sensor : Sensor
    sensor.sensorType = SensorType.Stationary
    sensor.dataDimensions = DataDimensions.TwoD
    sensor.workingRange = [2]f32 {0.1, 40}
    sensor.scanFrequency = 5.5;
    sensor.sampleFrequency = 3960;

    packetSize := cast(int)(sensor.sampleFrequency / sensor.scanFrequency);

    directions := make([]glm.vec4, packetSize)

    // initialization for 2D lidars
    if(sensor.dataDimensions == DataDimensions.TwoD){
        for i := 0; i < packetSize; i+=1 {
            angle : f32 = ((2.0 * math.PI)/cast(f32)packetSize) * cast(f32)i
            directions[i] = glm.normalize(glm.vec4{math.cos(angle), 0.0, math.sin(angle), 0.0})
        }
    }

    sensor.directions = directions
    sensor.packetSize = packetSize

    c := createCylinder()
    c.model = identityModel * glm.mat4Scale(glm.vec3{0.0556, 0.043, 0.0556})
    sensor.geometry = c;

    return sensor
}