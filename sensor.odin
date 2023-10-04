package main
import glm "core:math/linalg/glsl"

Sensor :: struct {
    sensorType: SensorType,
    dataDimensions: DataDimensions,
    scanFrequency: f32,
    sampleFrequency: f32,
    angularRange: f32,
    workingRange: [2]f32,
    geometry : Geometry
}

DataDimensions :: enum {
    TwoD,
    ThreeD
}

SensorType :: enum {
    Stationary
}

initializeSensor :: proc () -> Sensor {
    sensor : Sensor
    sensor.sensorType = SensorType.Stationary
    sensor.dataDimensions = DataDimensions.TwoD
    sensor.workingRange = [2]f32 {0.1, 100}
    sensor.scanFrequency = 10;
    sensor.sampleFrequency = 32000;

    c := createCylinder()
    c.model = identityModel * glm.mat4Scale(glm.vec3{0.0556, 0.043, 0.0556})
    sensor.geometry = c;

    return sensor
}