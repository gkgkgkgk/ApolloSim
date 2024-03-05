#version 330 core

out vec4 FragColor;
in vec3 pos;

void main() {
	if (pos.x > 0){
		FragColor = vec4(1.0, 0.0, 0.0, 0.75);
	} else if (pos.y > 0){
		FragColor = vec4(0.0, 1.0, 0.0, 0.75);
	} else if (pos.z > 0){
		FragColor = vec4(0.0, 0.0, 1.0, 0.75);
	} else {
		FragColor = vec4(0.0, 0.0, 0.0, 0.75);
	}
}