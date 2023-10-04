package main 
import "core:fmt"
import gl "vendor:OpenGL"
import "core:math"
import glm "core:math/linalg/glsl"

Geometry :: struct {
    vertices: [dynamic]f32,
    indices: [dynamic]u16,
    model : glm.mat4
}

createCube :: proc () -> Geometry {
    cube : Geometry
    cube.vertices = [dynamic]f32 {
        -0.5, -0.5, -0.5,  0.0, 0.0,
         0.5, -0.5, -0.5,  1.0, 0.0,
         0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
         0.5, -0.5,  0.5,  1.0, 0.0,
         0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
    };
    
    cube.indices = [dynamic]u16 {
        0, 1, 2, // Front
        2, 3, 0,

        4, 5, 6, // Back
        6, 7, 4,

        0, 4, 7, // Left
        7, 3, 0,

        1, 5, 6, // Right
        6, 2, 1,

        0, 1, 5, // Top
        5, 4, 0,

        2, 3, 7, // Bottom
        7, 6, 2
    };

    return cube;
}

createCylinder :: proc () -> Geometry {
    cylinder : Geometry

    numVertices := 36
    height : f32 = 1.0
    radius : f32 = 0.5

    vertices := [dynamic]f32 {}
    indices := [dynamic]u16 {}

    for i := 0; i < numVertices; i += 1 {
        theta := 2.0 * math.PI * f32(i) / f32(numVertices)
        x := radius * math.cos_f32(theta)
        z := radius * math.sin_f32(theta)

        append(&vertices, x, height / 2.0, z)
        append(&vertices, radius, radius)

        append(&vertices, x, -height / 2.0, z)
        append(&vertices, radius, radius)

        currentIndex := i * 2
        nextIndex := (i * 2 + 2) % (numVertices * 2)
        append(&indices, cast(u16)currentIndex, cast(u16)currentIndex + 1, cast(u16)nextIndex)
        append(&indices, cast(u16)nextIndex, cast(u16)currentIndex + 1, cast(u16)nextIndex + 1)
    }

    cylinder.vertices = vertices
    cylinder.indices = indices

    return cylinder;
}

drawGeometry :: proc (geometry : Geometry) {
    vbo, vao: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
	gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.BufferData(gl.ARRAY_BUFFER, len(geometry.vertices) * size_of(f32), &(geometry.vertices[0]), gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0);
	gl.EnableVertexAttribArray(0);
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32));
	gl.EnableVertexAttribArray(0);

	gl.BindBuffer(gl.ARRAY_BUFFER, 0);

    gl.DrawArrays(gl.TRIANGLES, 0, size_of(geometry.vertices));
    gl.BindVertexArray(0);
}

drawGeometryWithIndices :: proc (geometry : Geometry) {
    vbo, vao, ebo: u32;
    gl.GenVertexArrays(1, &vao); defer gl.DeleteVertexArrays(1, &vao);
    gl.GenBuffers(1, &vbo); defer gl.DeleteBuffers(1, &vbo);
    gl.GenBuffers(1, &ebo); defer gl.DeleteBuffers(1, &ebo);

    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);

    gl.BufferData(gl.ARRAY_BUFFER, len(geometry.vertices) * size_of(f32), &(geometry.vertices[0]), gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(geometry.indices) * size_of(u16), &(geometry.indices[0]), gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32));
    gl.EnableVertexAttribArray(1);

    gl.BindBuffer(gl.ARRAY_BUFFER, 0);

    gl.DrawElements(gl.TRIANGLES, cast(i32)len(geometry.indices), gl.UNSIGNED_SHORT, nil);
    gl.BindVertexArray(0);
}