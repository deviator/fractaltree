//### vert
#version 330

in vec4 pos;

uniform mat4 prj;

void main()
{ gl_Position = prj * pos; }

//### geom
#version 330

layout( triangles ) in;
//layout( line_strip, max_vertices = 2 ) out;
layout( triangle_strip, max_vertices = 3 ) out;

uniform vec4 col1;
uniform vec4 col2;

out vec4 ex_col;

void main()
{
    gl_Position = gl_in[0].gl_Position;
    ex_col = col1;
    EmitVertex();

    gl_Position = gl_in[1].gl_Position;
    ex_col = col2;
    EmitVertex();

    gl_Position = gl_in[2].gl_Position;
    ex_col = col1;
    EmitVertex();
    EndPrimitive();
}


//### frag
#version 330

in vec4 ex_col;
out vec4 color;

void main()
{
    color = ex_col;
}
