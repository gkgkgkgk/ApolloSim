package main

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

stepSimEngine :: proc (engine : SimEngine) {
   
}