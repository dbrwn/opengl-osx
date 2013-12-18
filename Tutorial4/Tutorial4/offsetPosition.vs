#version 330

layout (location = 0) in vec4 position;
layout (location = 1) in vec4 color;

uniform vec3 offset;

smooth out vec4 theColor;

void main()
{
    gl_Position = position + vec4(offset.x, offset.y, offset.z, 0.0);
    theColor = color;
}
