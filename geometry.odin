package main 
import "core:fmt"
import gl "vendor:OpenGL"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:strconv"
import stb "vendor:stb/image"
import "core:strings"

GeometryType:: enum {
    cube,
    sphere,
    cylinder,
    custom
}

Geometry :: struct {
    vertices: [dynamic]f32,
    indices: [dynamic]u16,
    model : glm.mat4,
    gType : int,
    material: Material,
    texturePath : string,
    texture : u32,
}

Geometry32 :: struct {
    model : glm.mat4,
    gType : int,
    vertices: [dynamic]f32,
    indices: [dynamic]i32,
}

Material :: struct {
    averageIntensity: f32,
    maxIntensity: f32,
    minIntensity: f32
}

SimpleGeometry :: struct {
    model : glm.mat4,
    gType : i32,
    material : i32
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

    cube.gType = 6;

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

    cylinder.gType = 1;

    return cylinder;
}

createMaterial :: proc (average:f32, max:f32, min:f32) -> Material {
    m : Material;
    m.averageIntensity = average;
    m.maxIntensity = max;
    m.minIntensity = min;

    return m;
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

    gl.BindTexture(gl.TEXTURE_2D, geometry.texture);

    gl.DrawElements(gl.TRIANGLES, cast(i32)len(geometry.indices), gl.UNSIGNED_SHORT, nil);

    gl.BindVertexArray(0);
}

addTexture :: proc (geometry : Geometry, path : string) -> Geometry {
    width, height, nrChannels : i32;
    data := stb.load(strings.clone_to_cstring(path), &width, &height, &nrChannels, 0);
    texture : u32;
    gl.GenTextures(1, &texture);
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
    gl.GenerateMipmap(gl.TEXTURE_2D);
    geometry := geometry;
    geometry.texture = texture;

    return geometry;
}

/* CUSTOM GEOMETRY LOADER */
/* Thank you to https://gist.github.com/vassvik/f4c19c35ba72ad52eaa51d1091d379d8 */

stream : string

is_whitespace :: proc(c: u8) -> bool {
	switch c {
	case ' ', '\t', '\n', '\v', '\f', '\r', '/': return true;
	}
	return false;
}

skip_whitespace :: proc() #no_bounds_check {
	for stream != "" && is_whitespace(stream[0]) do stream = stream[1 : len(stream)];
}

skip_line :: proc() #no_bounds_check {
	N := len(stream);
	for i := 0; i < N; i += 1 {
		if stream[0] == '\r' || stream[0] == '\n' {
			skip_whitespace();
			return;
		}
		stream = stream[1 : len(stream)];
	}
}

next_word :: proc() -> string {
	skip_whitespace();

	for i := 0; i < len(stream); i += 1 {
		if is_whitespace(stream[i]) || i == len(stream)-1 {
			current_word := stream[0 : i];
			stream = stream[i+1 : len(stream)];
			return current_word;
		}
	}
	return "";
}

customGeometry :: proc(filename: string) -> Geometry {
    to_f32 :: strconv.parse_f32;
    to_u16 :: proc(str: string) -> u16 { i, _ := strconv.parse_int(str); return cast(u16)i};
    geometry : Geometry;

    data, status := os.read_entire_file(filename);

    if !status {
        fmt.println("Failed to load ", filename);
        return geometry;
    };
    
    vertices: [dynamic] f32;
    indices: [dynamic] u16;

    stream = string(data);

    for stream != "" {
        current_word := next_word();

        switch current_word {
            case "v":
                v1, _ := to_f32(next_word())
                v2, _ := to_f32(next_word())
                v3, _ := to_f32(next_word())

                append(&vertices, v1)
                append(&vertices, v2)
                append(&vertices, v3)
                append(&vertices, 0)
                append(&vertices, 0)
            case "f":
                new_indices:[9]u16;
                for i := 0; i < 9; i+= 1 {
                    f := to_u16(next_word())
                    new_indices[i] = f - 1;
                }
                append(&indices, new_indices[0], new_indices[3], new_indices[6]);
        }
    }

    geometry.vertices = vertices
    geometry.indices = indices

    return geometry;
}