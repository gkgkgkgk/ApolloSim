package main

import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "vendor:glfw"
import "core:math"
import "core:fmt"

drawGrid :: proc($gridSize: int) {
    vertices : [6 * 2 * (gridSize+ 1)]f32;

    for i := 0; i < gridSize + 1; i += 1 {
        index := i * 12
        lineLength := (cast(f32)gridSize + 1) * 0.5;
        offset := cast(f32) i - lineLength + 0.5;
        // add vertical line
        vertices[index] = offset;
        vertices[index + 1] = 0;
        vertices[index + 2] = -lineLength+ 0.5;

        vertices[index + 3] = offset;
        vertices[index + 4] = 0;
        vertices[index + 5] = lineLength- 0.5;

        // add horizontal line
        vertices[index + 6] = -lineLength + 0.5;
        vertices[index + 7] = 0;
        vertices[index + 8] = offset;

        vertices[index + 9] = lineLength - 0.5;
        vertices[index + 10] = 0;
        vertices[index + 11] = offset;
    }

    vbo, vao, ebo: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);

    gl.DrawArrays(gl.LINES, 0, (cast(i32)gridSize + 1) * 4);
}