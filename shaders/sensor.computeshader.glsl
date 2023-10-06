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

vec3 rayBoxIntersection(vec3 rayOrigin, vec3 rayDir, mat4 modelMatrix) {
    // Inverse of the model matrix to transform the ray to local space
    mat4 inverseModelMatrix = inverse(modelMatrix);

    // Transform the ray into local space
    vec4 localRayOrigin = inverseModelMatrix * vec4(rayOrigin, 1.0);
    vec4 localRayDir = inverseModelMatrix * vec4(rayDir, 0.0);

    // Calculate the inverse of the ray direction for faster intersection tests
    vec3 invRayDir = 1.0 / localRayDir.xyz;

    // Box bounds in local space (-0.5 to 0.5 along each axis)
    vec3 minBounds = vec3(-0.5);
    vec3 maxBounds = vec3(0.5);

    // Calculate intersection distances for each axis
    vec3 tMin = (minBounds - localRayOrigin.xyz) * invRayDir;
    vec3 tMax = (maxBounds - localRayOrigin.xyz) * invRayDir;

    // Find the largest minimum intersection distance
    float tEnter = max(max(max(tMin.x, tMin.y), tMin.z), 0.0);

    // Find the smallest maximum intersection distance
    float tExit = min(min(min(tMax.x, tMax.y), tMax.z), 1.0);

    // Check if there is a valid intersection
    if (tEnter <= tExit) {
        // Calculate the intersection point in local space
        vec3 intersectionPointLocal = localRayOrigin.xyz + tEnter * localRayDir.xyz;

        // Transform the intersection point back to world space
        vec4 intersectionPointWorld = modelMatrix * vec4(intersectionPointLocal, 1.0);

        return intersectionPointWorld.xyz;
    } else {
        // No intersection
        return vec3(-1.0); // You can return any suitable value for no intersection
    }
}

void main()
{
    uvec3 globalID = gl_GlobalInvocationID;
    vec3 intersection = rayBoxIntersection(vec3(0), vec3(1, 0, 0), scene[0].model);
    outputData[globalID.x] = intersection;
}