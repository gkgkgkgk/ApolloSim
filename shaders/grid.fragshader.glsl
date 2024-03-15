#version 330 core

out vec4 FragColor;
in vec3 pos;

void main() {
	if (length(pos) < 10) {
		FragColor = vec4(0.0, 0.0, 0.0, 0.25);
	} else {
		float fadeFactor = clamp((length(pos) - 10.0) / (20.0 - 10.0), 0.0, 1.0);
		float alpha = mix(0.25, 0.0, fadeFactor);
		vec4 color = vec4(0.0, 0.0, 0.0, alpha);
		
		FragColor = color;
	}
	
}