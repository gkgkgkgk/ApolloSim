#version 460 core
layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

struct SimpleGeometry
{
    mat4 model;
    int gType;
};

layout(std430, binding = 0) buffer InputBuffer {
    SimpleGeometry scene[];
};
layout(std430, binding = 1) buffer OutputBuffer {
    vec3 outputData[];
};

struct IntersectionResult {
    bool intersects;
    vec3 point;
};

IntersectionResult rayIntersectsCube(vec3 rayOrigin, vec3 rayDirection, vec3 cubeMin, vec3 cubeMax) {
    IntersectionResult result;
    result.intersects = false;
    result.point = vec3(0.0);

    vec3 t1 = (cubeMin - rayOrigin) / rayDirection;
    vec3 t2 = (cubeMax - rayOrigin) / rayDirection;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float tNear = max(max(tmin.x, tmin.y), tmin.z);
    float tFar = min(min(tmax.x, tmax.y), tmax.z);

    if (tNear <= tFar) {
        result.intersects = true;
        result.point = rayOrigin + tNear * rayDirection;
    }

    return result;
}

void main()
{
    uvec3 globalID = gl_GlobalInvocationID;
    outputData[globalID.x] = vec3(float(scene[0].gType),2,1);
}