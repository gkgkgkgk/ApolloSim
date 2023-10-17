#version 330 core

in float fragIntensity;
out vec4 FragColor;

void main() {
	FragColor = vec4(1.0, 0.0, 0.0, fragIntensity);
}