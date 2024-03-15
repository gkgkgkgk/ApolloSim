#version 330 core

out vec4 FragColor;
in vec3 pos;

void main() {
	if (length(pos) < 10) {
		FragColor = vec4(0.0, 0.0, 0.0, 0.25);
	} else {
		float fadeFactor = clamp((length(pos) - 10.0) / (20.0 - 10.0), 0.0, 1.0);
		
		// Interpolate the alpha value from 1.0 (fully visible) to 0.0 (fully invisible)
		float alpha = mix(0.25, 0.0, fadeFactor);
		
		// Example color, modify this vec4 to the desired color
		vec4 color = vec4(0.0, 0.0, 0.0, alpha); // Assuming white color, modify as needed
		
		FragColor = color;
	}
	
}