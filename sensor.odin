package main

Sensor :: struct {
    sensorType: SensorType,
    dataDimensions: DataDimensions,
    workingRange: [2]f32
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

    return sensor
}