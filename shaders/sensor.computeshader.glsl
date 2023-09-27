#version 460 core
layout (local_size_x = 10, local_size_y = 1, local_size_z = 1) in;
layout(std430, binding = 0) buffer InputBuffer {
    int inputData[];
};
layout(std430, binding = 1) buffer OutputBuffer {
    int outputData;
};
void main()
{
    uvec3 globalID = gl_GlobalInvocationID;
    outputData = inputData[2] * 10;
}