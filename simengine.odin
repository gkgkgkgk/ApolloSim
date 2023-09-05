package main
import "core:fmt"

SimEngine :: struct {
    steps : int
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
    fmt.printf("Performed step %s", engine.steps)

    engine.steps = engine.steps + 1
    return engine
}