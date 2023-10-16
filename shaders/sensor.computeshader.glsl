#version 460 core
layout (local_size_x = 32, local_size_y = 10, local_size_z = 3) in;

struct SimpleGeometry
{
    mat4 model;
    int gType;
};

layout(std430, binding = 0) buffer InputBuffer {
    SimpleGeometry scene[];
};

layout(std430, binding = 1) buffer InputBuffer2 {
    vec3 directions[];
};

layout(std430, binding = 2) buffer OutputBuffer {
    vec3 outputData[];
};

struct IntersectionResult {
    bool intersects;
    vec3 point;
};

IntersectionResult rayBoxIntersection(vec3 rayOrigin, vec3 rayDirection, mat4 modelMatrix) {
    IntersectionResult result = IntersectionResult(false, rayOrigin);
    vec3 position = modelMatrix[3].xyz;
    float cubeHalfSize = length(modelMatrix[0].xyz) * 0.5;
    
    vec3 minExtents = position - vec3(cubeHalfSize);
    vec3 maxExtents = position + vec3(cubeHalfSize);

    float tMin = 0.0;
    float tMax = 1e30;

    for (int i = 0; i < 3; i++) {
        if (abs(rayDirection[i]) < 1e-6) {
            if (rayOrigin[i] < minExtents[i] || rayOrigin[i] > maxExtents[i]) {
                return result;
            }
        } else {
            // Ray is not parallel
            float t0 = (minExtents[i] - rayOrigin[i]) / rayDirection[i];
            float t1 = (maxExtents[i] - rayOrigin[i]) / rayDirection[i];

            if (t0 > t1) {
                float temp = t0;
                t0 = t1;
                t1 = temp;
            }

            tMin = max(t0, tMin);
            tMax = min(t1, tMax);

            if (tMin > tMax) {
                return result;
            }
        }
    }

    result.point = rayOrigin + rayDirection * tMin;
    result.intersects = true;
    return result;
}

void main()
{
    uvec3 id = gl_LocalInvocationID;
    // int index = id.x + 32 * (id.y + 10 * id.z);
    IntersectionResult intersection = rayBoxIntersection(vec3(0), normalize(directions[id.x]), scene[0].model);

    if (intersection.intersects){
        outputData[id.x] = intersection.point;
    } else {
        outputData[id.x] = vec3(0);
    }
}