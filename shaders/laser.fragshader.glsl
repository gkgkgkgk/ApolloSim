#version 330 core

in float fragIntensity;
out vec4 FragColor;

void main() {
    float red = 1.0 - fragIntensity;
    float green = 1.0 - fragIntensity;
    float blue = fragIntensity;

    if (fragIntensity <= 0.0f){
        FragColor = vec4(1.0f, 0.0f, 0.0f, 0.1f);
    }
    else {
        FragColor = vec4(0, green, blue, 1.0f);
    }
}