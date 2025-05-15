#version 430 core
precision highp float;

layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f, binding = 0) uniform image2D img_output;

layout(location = 2) uniform float max_p = 1;
layout(location = 3) uniform int min_p = 10;

//define x^3 - 1
//define x = vec2

layout(std430, binding = 1) buffer rx
{
	float datax[];
};
layout(std430, binding = 2) buffer ry
{
	float datay[];
};

vec3 color_map_viridis(float data) {
	vec3 colors[9] = {
	vec3( 0.267, 0.005, 0.329 ),  // x = 0    (Dark Purple)
	vec3(0.282, 0.137, 0.455 ),  // x = 32   (Deep Blue)
	vec3(0.192, 0.408, 0.557 ),  // x = 64   (Blue)
	vec3(0.122, 0.612, 0.537 ),  // x = 96   (Teal)
	vec3(0.208, 0.718, 0.474 ),  // x = 128  (Greenish)
	vec3(0.427, 0.804, 0.349 ),  // x = 160  (Green-Yellow)
	vec3(0.706, 0.871, 0.169 ),  // x = 192  (Yellow-Green)
	vec3(0.914, 0.906, 0.118 ),  // x = 224  (Bright Yellow)
	vec3(0.992, 0.906, 0.141 )   // x = 255  (Almost White-Yellow)
	};
	int x_values[9] = { 0, 32, 64, 96, 128, 160, 192, 224, 255 };
	//find the index:
	int index = -1;
	for (int i = 0; i < 9; i++) {
		index = i;
		if (x_values[index] > data)break;
	}
	if (index == 0 || index == 8) return colors[index];
	//interpolate 
	float xi = data - x_values[index - 1];
	float xk = x_values[index] - data;
	float xj = x_values[index] - x_values[index - 1];
	return (xi * colors[index] + colors[index - 1] * xk) / xj;
}

vec4 color_map(float data) {
	//data -= 0.01f;
	//data = abs(data);
	if (data < 0.166f) {
		return vec4(0.0, 0.0, data * 6, 1.0f);
	}
	if (data < 0.333f) {
		return vec4(0.0, (data - 0.1666f) * 6, 1.0f,  1.0);
	}
	if (data < 0.5f) {
		return vec4(0.0,  1.0, 1.0 - (data - 0.33f) * 6, 1.0);
	}
	if (data < 0.666f) {
		return vec4((data - 0.5f) * 6, 1.0, 0.0f, 1.0);
	}
	if (data < 0.8333f) {
		return vec4(1.0, 1.0 - (data - 0.66f) * 6, 0.0, 1.0);
	}
	if (data < 1.0f) {
		return vec4(1.0 - (data - 0.833f) * 6, 0.0f, 0.0, 1.0);
	}
	return vec4(1, 1, 1, 1);
}
vec4 color_map2(float data) {
	data = abs(data);
	if (data < 0.166f) {
		return vec4(0.0, data * 6, 0.0, 1.0f);
	}
	if (data < 0.333f) {
		return vec4(0.0, 1.0f, (data - 0.1666f) * 6, 1.0);
	}
	if (data < 0.5f) {
		return vec4(0.0, 1.0 - (data - 0.33f) * 6, 1.0, 1.0);
	}
	if (data < 0.666f) {
		return vec4((data - 0.5f) * 6, 0.0, 1.0f, 1.0);
	}
	if (data < 0.8333f) {
		return vec4(1.0, 0.0f, 1.0 - (data - 0.66f) * 6, 1.0);
	}
	if (data < 1.0f) {
		return vec4(1.0 - (data - 0.833f) * 6, 0.0f, 0.0, 1.0);
	}
	return vec4(0, 0, 1, 1);
}
uint n =  400;
uint nx = 400;
uniform float w = 0.0;
uniform float ws = 2;
void main() {
	float data = datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * n];
	vec4 color = color_map(datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * n]);// : color_map(datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * n]);
	//color = vec4(1, 1, 1, 1);
	//vec4(datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y *n], datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * n], datax[gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * n], 1.0);
	/*if (dx >= 0 && dx < 1) {
		float dy = 0.2969 * sqrt(dx) - 0.126 * dx - 0.3516 * dx * dx + 0.2843 * dx * dx * dx - 0.1015 * dx * dx * dx * dx;
		if (abs(dy) > 0.01f * abs(cy))color = vec4(.1, .2, 0.2, 0);
	}*/
	/*if ((gl_GlobalInvocationID.x * 1.0f - 300/4) * (gl_GlobalInvocationID.x * 1.0f - 300/4) + (gl_GlobalInvocationID.y * 1.0f - 100) * (gl_GlobalInvocationID.y * 1.0f - 100) < 100) {
		color = vec4(0.0, .5, 1.0, 1);
	}*/
	imageStore(img_output, ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y), color);
}