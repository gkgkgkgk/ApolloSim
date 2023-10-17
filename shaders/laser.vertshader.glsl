#version 330 core
layout (location = 0) in vec4 aPos;

out float fragIntensity;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view  * model * vec4(aPos.xyz, 1.0);
    fragIntensity = aPos.w;
}