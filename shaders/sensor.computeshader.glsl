#version 460 core
layout (local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

struct SimpleGeometry
{
    mat4 model;
    int gType;
};

struct ComplexGeometry
{
    float vertices[128];
    int indices[255];
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

layout(std430, binding = 3) buffer InputBuffer3 {
    ComplexGeometry complexScene[];
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

bool IntersectRayTriangle(vec3 rayOrigin, vec3 rayDirection, vec3 v0, vec3 v1, vec3 v2, inout IntersectionResult result) {
    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;
    vec3 h = cross(rayDirection, edge2);
    float a = dot(edge1, h);

    if (abs(a) < 1e-5) {
        result.intersects = false;
        return false;
    }

    float f = 1.0 / a;
    vec3 s = rayOrigin - v0;
    float u = f * dot(s, h);

    if (u < 0.0 || u > 1.0) {
        result.intersects = false;
        return false;
    }

    vec3 q = cross(s, edge1);
    float v = f * dot(rayDirection, q);

    if (v < 0.0 || u + v > 1.0) {
        result.intersects = false;
        return false;
    }

    float t = f * dot(edge2, q);

    if (t > 1e-5) {
        result.intersects = true;
        result.point = rayOrigin + rayDirection * t;
        return true;
    }

    result.intersects = false;
    return false;
}

IntersectionResult complexMeshIntersection(vec3 rayOrigin, vec3 rayDirection, ComplexGeometry geometry) {
    IntersectionResult result = IntersectionResult(false, rayOrigin);

    for (int i = 0; i < 256; i += 3) {
        int i0 = geometry.indices[i];
        int i1 = geometry.indices[i + 1];
        int i2 = geometry.indices[i + 2];

        // if(i0 == i1 && i0 == i2){
        //     break;
        // }

        vec3 v0 = vec3(geometry.vertices[i0 * 5], geometry.vertices[i0 * 5 + 1], geometry.vertices[i0 * 5 + 2]);
        vec3 v1 = vec3(geometry.vertices[i1 * 5], geometry.vertices[i1 * 5 + 1], geometry.vertices[i1 * 5 + 2]);
        vec3 v2 = vec3(geometry.vertices[i2 * 5], geometry.vertices[i2 * 5 + 1], geometry.vertices[i2 * 5 + 2]);

        IntersectRayTriangle(rayOrigin, rayDirection, v0, v1, v2, result);
    }
    
    return result;
}

void main()
{
    uvec3 id = gl_LocalInvocationID;
    int count = directions.length()/16;
    for(int i = 0; i < count; i++){
        IntersectionResult result = IntersectionResult(false, vec3(10000000.0));

        // for(int j = 0; j < scene.length(); j++){
        //     IntersectionResult newIntersection = rayBoxIntersection(vec3(0), normalize(directions[id.x * count + i]), scene[j].model);

        //     if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
        //         result = newIntersection;
        //     }
        // }

        for(int j = 0; j < complexScene.length(); j++){
            IntersectionResult newIntersection = rayBoxIntersection(vec3(0), normalize(directions[id.x * count + i]), complexScene[j].model);

            if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
                result = newIntersection;
            }
        }

        if (result.intersects){
            outputData[id.x * count + i] = result.point;
        } else {
            outputData[id.x * count + i] = vec3(0);
        }
    }
}