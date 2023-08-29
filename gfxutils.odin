package main

import gl "vendor:OpenGL"
import glm "core:math/linalg/glsl"
import "vendor:glfw"
import "core:math"
import "core:fmt"

drawGrid :: proc() {
    gridSize : int = 10;
    stepSize : f32 = 1.0;
    halfSize : f32 = cast(f32)gridSize * stepSize * 0.5;

    vertices : [100]f32;
    for i := 0; i < gridSize; i += 1 {
        offset : f32 = cast(f32)i * stepSize - halfSize;

        vertices[i * 4] = offset;       // x1
        vertices[i * 4 + 1] = halfSize; // y1
        vertices[i * 4 + 2] = offset;   // x2
        vertices[i * 4 + 3] = -halfSize;// y2
    }

    vbo, vao, ebo: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 2 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);

    gl.DrawArrays(gl.LINES, 0, cast(i32)gridSize * 2);
}