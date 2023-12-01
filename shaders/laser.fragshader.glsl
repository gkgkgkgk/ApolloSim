#version 330 core

in float fragIntensity;
out vec4 FragColor;

void main() {
    float red = 1.0 - fragIntensity;
    float green = 1.0 - fragIntensity;
    float blue = fragIntensity;

    FragColor = vec4(0, green, blue, fragIntensity);
}