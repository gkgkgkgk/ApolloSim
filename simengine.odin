package main
import "core:fmt"

SimEngine :: struct {
    steps : int,
    sensor : Sensor
}

initializeSimEngine :: proc () -> SimEngine {
    engine : SimEngine
    engine.steps = 0
    engine.sensor = initializeSensor();

    return engine
}

stepSimEngine :: proc (engine : SimEngine) -> SimEngine{
    engine := engine
    fmt.printf("Performed step %d to gather %f points. \n", engine.steps, engine.sensor.sampleFrequency / engine.sensor.scanFrequency)

    // At this point, the calculation should be handed off to a compute shader for parellel processing.

    engine.steps = engine.steps + 1
    return engine
}