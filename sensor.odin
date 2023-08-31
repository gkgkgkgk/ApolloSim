package main

Sensor :: struct {
    sensorType: SensorType,
    dataDimensions: DataDimensions,
    workingRange: [2]f32
}

DataDimensions :: enum {
    TwoD,
    ThreeD
}

SensorType :: enum {
    Stationary
}