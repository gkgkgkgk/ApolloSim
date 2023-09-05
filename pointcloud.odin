package main
import glm "core:math/linalg/glsl"

PointCloud :: struct {
    points : [dynamic] Point
}

Point :: struct {
    position : glm.vec3
}