//### vert
#version 330

in vec4 pos;
in vec4 col;

uniform mat4 prj;

out vec4 v_col;

void main()
{
    gl_Position = prj * pos;
    v_col = col;
}

//### frag
#version 330

in vec4 v_col;
out vec4 color;

void main()
{
    color = v_col;
}
