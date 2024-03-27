#version 460 core

#define PI 3.1415926535897932384626433832795

layout (local_size_x = 16, local_size_y = 1, local_size_z = 1) in;

uniform float u_time;

// RANDOM FUNCTIONS
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

bool dropsRay(vec2 co, float dropRate){
    float randomValue = rand(co);
    return false;
    return randomValue < dropRate ? true : false;
}

float sampleNormalDistribution(vec2 uv, float mean, float stdDev)
{
    float u1 = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float u2 = fract(sin(dot(uv, vec2(93.9898, 67.345))) * 24634.6345);

    u1 = u1 == 0.0 ? 0.0001 : u1;
    float r = sqrt(-2.0 * log(u1));
    float theta = 2.0 * PI * u2;

    float z = r * cos(theta);

    return z * stdDev + mean;
}

// BRDF Functions
float BRDFOrenNayar(float roughness, float theta_i) {
    float sigma2 = roughness * roughness;
    float A = 1.0 - (0.5 * sigma2 / (sigma2 + 0.33));
    float B = 0.45 * sigma2 / (sigma2 + 0.09);
    float cosTheta = cos(theta_i);

    // Avoiding division by zero as theta_i approaches pi/2.
    float sinTheta = sin(theta_i);
    float tanTheta = (abs(cosTheta) > 0.001) ? (sinTheta / cosTheta) : 0.0;

    float BRDF = A + B * sinTheta * tanTheta;
    BRDF = clamp(BRDF, 0.0, 1.0);

    return BRDF;
}

// Schlicks approximation
float FresnelSchlick(float cosTheta, float F0) {
    return F0 + (1 - F0) * pow(1.0 - cosTheta, 5.0);
}

float GeometrySchlickGGX(float NdotV, float roughness) {
    float alpha = roughness * roughness;
    float k = (alpha + 1) * (alpha + 1) / 8.0;
    return NdotV / (NdotV * (1 - k) + k);
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float alpha) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, V), 0.0);

    return GeometrySchlickGGX(NdotV, alpha) * GeometrySchlickGGX(NdotL, alpha);
}

float GGXDistribution(vec3 N, vec3 V, float roughness) {
    float alpha = roughness * roughness;
    float NdotV = max(dot(N, V), 0.0);
    float NdotV2 = NdotV * NdotV;
    float denom = NdotV2 * (alpha * alpha - 1.0) + 1.0;
    return alpha * alpha / (PI * denom * denom);
}

// Assuming L = -V for LiDAR
float BRDFCookTorrance(vec3 N, vec3 V, float roughness, float F0) {
    float NdotV = max(dot(N, V), 0.0);

    float F = FresnelSchlick(NdotV, F0);
    float G = GeometrySchlickGGX(NdotV, roughness);
    float D = GGXDistribution(N, V, roughness);

    float specularReflection = F * G * D / (4.0 * NdotV * NdotV + 0.0001);

    return specularReflection;
}

// STRUCTS
struct Material 
{
    int id;
    int brdfType; // 0 for ON, 1 for CT,
    float roughness;
    float fresnel;
    bool isReal;
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

struct IntersectionResult {
    bool intersects;
    vec3 point;
    float intensity;
};

struct AngleData {
    float angleDeg;
    int materialId;
    float meanIntensity;
    float meanDistance;
    float stdevIntensity;
    float stdevDistance;
    float dropRate;
};

// INPUT/OUTPUT LAYOUTS
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

layout(std430, binding = 7) buffer InputBuffer7 {
    float seeds[];
};

layout(std430, binding = 8) buffer InputBuffer8 {
    AngleData angles[];
};

layout(std430, binding = 9) buffer OutputBuffer2 {
    vec4 outputData2[];
};

AngleData closestAngle(int material, float angleDeg, out bool maximum) {
    AngleData closest;
    bool found = false;
    float minError = 10000.0;
    float maxAngleForMaterial = -10000.0;

    for (int i = 0; i < angles.length(); i++) {
        if (angles[i].materialId == material) {
            float currentError = abs(angles[i].angleDeg - angleDeg);
            if (currentError < minError) {
                minError = currentError;
                closest = angles[i];
                found = true;
            }
            if (angles[i].angleDeg > maxAngleForMaterial) {
                maxAngleForMaterial = angles[i].angleDeg;
            }
        }
    }

    if (found) {
        maximum = (closest.angleDeg == maxAngleForMaterial && angleDeg > maxAngleForMaterial);

        return closest;
    } else {
        closest.angleDeg = 0.0;
        closest.materialId = -1;
        closest.meanIntensity = -10.0;
        closest.meanDistance = 0.0;
        closest.stdevIntensity = 0.0;
        closest.stdevDistance = 0.0;
        closest.dropRate = 0.0;
        maximum = false;
        return closest;
    }
}

bool shouldDrop(float rate, vec2 coord) {
    float rand = rand(coord);
    return rand < rate;
}

Material findMaterial(int id) {
    for (int i = 0; i < materials.length(); i++){
        if (materials[i].id == id){
            return materials[i];
        }
    }

    return materials[0];
}

IntersectionResult rayBoxIntersection(int rayId, vec3 rayOrigin, vec3 rayDirection, mat4 modelMatrix, int material) {
    IntersectionResult result = IntersectionResult(false, rayOrigin, 0.0);

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

    vec3 normal = vec3(0);
    
    float e = 0.0001;
    for (int i = 0; i < 3; i++) {
        if(abs(result.point[i] - maxExtents[i]) < e){
            normal[i] = 1.0;
            break;
        }
    
        if(abs(result.point[i] - minExtents[i]) < e){
            normal[i] = -1.0;
            break;
        }
    }

    vec3 ray = normalize(rayDirection - rayOrigin);

    float angle = acos(abs(dot(ray, normal)));

    if (angle > (PI/2.0)) {
        angle = PI - angle;
    }

    float angleDeg = angle * 180.0 / PI;

    bool maximum = false;
    AngleData a;
    Material mat = findMaterial(material);
    
    if (mat.isReal){
        a = closestAngle(material, angleDeg, maximum);
    }

    result.point = rayOrigin + rayDirection * (tMin + sampleNormalDistribution(vec2(rayId, rayId / u_time), 0.0, a.stdevDistance));

    if(maximum || !mat.isReal) {
        vec3 L = ray;
        vec3 V = -ray;
        vec3 N = normal;

        float theta_i = acos(dot(L, N));
        float theta_o = acos(dot(N, V));

        float intensity = 0.0;

        if (mat.brdfType == 0){
            intensity = BRDFOrenNayar(mat.roughness, theta_i);
        } else {
            intensity = BRDFCookTorrance(N, V, mat.roughness, 0.5);
        }

        // the rplidar a1 has a binary intensity value, so clamp it to 0 or 1.
        if(intensity < 0.5){
            intensity = 0.0;
        } else {
            intensity = 1.0;
        }
    } else {
        if (shouldDrop(a.dropRate, vec2(rayId, rayId / u_time))){
            result.intensity = 0.0;
        } else {
            result.intensity = sampleNormalDistribution(vec2(rayId, rayId / u_time), a.meanIntensity / 47.0, a.stdevIntensity / 47.0);
        }
    }

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

IntersectionResult complexMeshIntersection(int rayId, vec3 rayOrigin, vec3 rayDirection, ComplexGeometry geometry) {
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
            result.intensity = sampleNormalDistribution(vec2(rayId, rayId / u_time), 0.5, 0.0);
        }
    }
    
    return result;
}

void main()
{
    uvec3 id = gl_LocalInvocationID;
    int count = directions.length()/16;
    for(int i = 0; i < count; i++){
        int rayId = int(id.x) + 10*int(id.y) + 100 * int(id.z) + 1000 * i;
        int index = int(id.x) * count + i;

        IntersectionResult result = IntersectionResult(false, vec3(10000000.0), 0.5);

        for(int j = 0; j < scene.length(); j++){
            IntersectionResult newIntersection = rayBoxIntersection(index, vec3(0), normalize(directions[index]), scene[j].model, scene[j].material);

            if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
                result = newIntersection;
            }
        }

        for(int j = 0; j < complexScene.length(); j++){
            IntersectionResult newIntersection = complexMeshIntersection(index, vec3(0), normalize(directions[index]), complexScene[j]);

            if (!result.intersects || (newIntersection.intersects && newIntersection.point.length() < result.point.length())) {
                result = newIntersection;
            }
        }

        outputData2[id.x * count + i] = vec4(directions[index], 1.0);

        if (result.intersects){
            outputData[id.x * count + i] = vec4(result.point, result.intensity);
        } else {
            outputData[id.x * count + i] = vec4(0.0, 0.0, 0.0, -1.0);
        }
    }
}