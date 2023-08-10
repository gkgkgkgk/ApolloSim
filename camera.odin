package main

import glm "core:math/linalg/glsl"
import "vendor:glfw"
import "core:math"
import "core:fmt"

Camera :: struct {
    pos: glm.vec3,
	up: glm.vec3,
	front: glm.vec3,
    right: glm.vec3,
    yaw: f32,
    pitch: f32,
    speed: f32,
    sensitivity: f32
}

getCameraViewMatrix :: proc(camera: Camera) -> glm.mat4 {
    return glm.mat4LookAt(camera.pos, camera.pos + camera.front, camera.up)
}

updateCamera :: proc(oldCam: Camera, deltaTime: f32, mouseMovement: glm.vec2, window: glfw.WindowHandle) -> Camera {
    newCam := oldCam;
    
    movement := glm.vec3{0.0, 0.0, 0.0};

    if(glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
        movement += newCam.front * newCam.speed;
    }
    if(glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS){
        movement += newCam.front * -newCam.speed;
    }
    if(glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS){
        movement += newCam.right * newCam.speed;
    }
    if(glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS){
        movement += newCam.right * -newCam.speed;
    }
 
    newCam.pos = oldCam.pos + movement * deltaTime;

    newCam.yaw -= mouseMovement.x * newCam.sensitivity;
    newCam.pitch += mouseMovement.y * newCam.sensitivity;

    if(newCam.pitch > 89.0){
        newCam.pitch = 89.0;
    }
    if(newCam.pitch < -89.0){
        newCam.pitch = -89.0;
    }

    newCam.front.x = math.cos(glm.radians(newCam.yaw)) * math.cos(glm.radians(newCam.pitch))
    newCam.front.y = math.sin(glm.radians(newCam.pitch))
    newCam.front.z = math.sin(glm.radians(newCam.yaw)) * math.cos(glm.radians(newCam.pitch))

    newCam.right = glm.normalize(glm.cross(newCam.front, glm.vec3{0.0, 1.0, 0.0}))
    newCam.up = glm.normalize(glm.cross(newCam.right, newCam.front))

    fmt.println(newCam.front)

    return newCam;
}