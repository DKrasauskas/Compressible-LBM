#version 330 core
#define SMOOTH 0

out vec4 FragColor;
in vec3 pos;

uniform sampler2D tex;

void main()
{
	vec2 norm = (pos.xy + 1.0f) / 2.0f;
	FragColor = texture(tex, norm);
}