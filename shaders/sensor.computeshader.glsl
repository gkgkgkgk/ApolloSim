#version 460 core
layout (local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

struct Material 
{
    float averageIntensity;
    float maxIntensity;
    float minIntensity;
};

struct SimpleGeometry
{
    mat4 model;
    int gType;
    int material;
};

struct ComplexGeometry
{
    mat4 model;
    int gType;
    float vertices[120];
    int indices[120];
};

layout(std430, binding = 0) buffer InputBuffer {
    SimpleGeometry scene[];
};

layout(std430, binding = 1) buffer InputBuffer2 {
    vec3 directions[];
};

layout(std430, binding = 2) buffer InputBuffer3 {
    ComplexGeometry complexScene[];
};

layout(std430, binding = 3) buffer InputBuffer4 {
    float vertices[];
};

layout(std430, binding = 4) buffer InputBuffer5 {
    int indices[];
};

layout(std430, binding = 5) buffer OutputBuffer {
    vec4 outputData[];
};

layout(std430, binding = 6) buffer InputBuffer6 {
    Material materials[];
};

struct IntersectionResult {
    bool intersects;
    vec3 point;
    float intensity;
};

IntersectionResult rayBoxIntersection(vec3 rayOrigin, vec3 rayDirection, mat4 modelMatrix, int material) {
    IntersectionResult result = IntersectionResult(false, rayOrigin, 0.0);
    result.intensity = materials[material].averageIntensity;

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

IntersectionResult IntersectRayTriangle(vec3 rayOrigin, vec3 rayDirection, vec3 v0, vec3 v1, vec3 v2) {
    IntersectionResult result = IntersectionResult(false, rayOrigin, 0.0);
    vec3 edge1 = v1 - v0;
    vec3 edge2 = v2 - v0;
    vec3 h = cross(rayDirection, edge2);
    float a = dot(edge1, h);

    if (abs(a) < 1e-5) {
        result.intersects = false;
        return result;
    }

    float f = 1.0 / a;
    vec3 s = rayOrigin - v0;
    float u = f * dot(s, h);

    if (u < 0.0 || u > 1.0) {
        result.intersects = false;
        return result;
    }

    vec3 q = cross(s, edge1);
    float v = f * dot(rayDirection, q);

    if (v < 0.0 || u + v > 1.0) {
        result.intersects = false;
        return result;
    }

    float t = f * dot(edge2, q);

    if (t > 1e-5) {
        result.intersects = true;
        result.point = rayOrigin + rayDirection * t;
        return result;
    }

    result.intersects = false;
    return result;
}

IntersectionResult complexMeshIntersection(vec3 rayOrigin, vec3 rayDirection, ComplexGeometry geometry) {
    IntersectionResult result = IntersectionResult(false, rayOrigin, 0.0);

    for (int i = 0; i < vertices.length(); i += 3) {
        int i0 = indices[i];
        int i1 = indices[i + 1];
        int i2 = indices[i + 2];

        if(i0 == i1 && i0 == i2){
            break;
        }

        vec3 v0 = (geometry.model * vec4(vertices[i0 * 5], vertices[i0 * 5 + 1], vertices[i0 * 5 + 2], 1)).xyz;
        vec3 v1 = (geometry.model * vec4(vertices[i1 * 5], vertices[i1 * 5 + 1], vertices[i1 * 5 + 2], 1)).xyz;
        vec3 v2 = (geometry.model * vec4(vertices[i2 * 5], vertices[i2 * 5 + 1], vertices[i2 * 5 + 2], 1)).xyz;

        IntersectionResult newIntersection = IntersectRayTriangle(rayOrigin, rayDirection, v0, v1, v2);

        if(newIntersection.intersects){
            result = newIntersection;
        }
    }
    
    return result;
}

float intensity(IntersectionResult result){
    return sin(result.point.x * 100.0);
}

void main()
{
    uvec3 id = gl_LocalInvocationID;
    int count = directions.length()/16;
    for(int i = 0; i < count; i++){
        IntersectionResult result = IntersectionResult(false, vec3(10000000.0), 0.5);

        for(int j = 0; j < scene.length(); j++){
            IntersectionResult newIntersection = rayBoxIntersection(vec3(0), normalize(directions[id.x * count + i]), scene[j].model, scene[j].material);

            if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
                result = newIntersection;
            }
        }

        for(int j = 0; j < complexScene.length(); j++){
            IntersectionResult newIntersection = complexMeshIntersection(vec3(0), normalize(directions[id.x * count + i]), complexScene[j]);

            if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
                result = newIntersection;
                result.intensity = 0.5;
            }
        }

        if (result.intersects){
            outputData[id.x * count + i] = vec4(result.point, result.intensity);
        } else {
            outputData[id.x * count + i] = vec4(0);
        }
    }
}