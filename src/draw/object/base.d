module draw.object.base;

public import std.math;
public import des.util;
public import des.view;
public import des.gl;

class DrawObject : GLSimpleObject, SpaceNode
{
    mixin SpaceNodeHelper!false;

protected:

    GLBuffer pos, col;

    abstract void prepareBuffers();

public:

    this()
    {
        import std.file;
        super( readText( appPath( "..", "data", "shaders", "object.glsl" ) ) );

        prepareBuffers();
    }

    @property
    {
        mat4 matrix() const { return self_mtr; }
        mat4 matrix( in mat4 m ) { self_mtr = m; return self_mtr; }

        bool needDraw() const { return draw_flag; }
        void needDraw( bool nd ) { draw_flag = nd; }
    }
}
