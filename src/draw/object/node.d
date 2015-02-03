module draw.object.node;

import draw.object.base;

import std.random;

class DrawNode : DrawObject
{
protected:
    vec4 scol1 = vec4(1);
    vec4 scol2 = vec4(1);

    bool color_changed = true;

    float seg_len = 2;

    override void prepareBuffers()
    {
        auto loc = shader.getAttribLocations( "pos" );
        pos = createArrayBuffer;
        setAttribPointer( pos, loc[0], 3, GLType.FLOAT );

        pos.setData( [ vec3(0,0,0), vec3(seg_len*0.381,.1,0), vec3(seg_len,0,0) ] );

        glLineWidth(2);
    }

    DrawNode[] child;
    mat4 initmtr;

public:

    this( size_t count )
    {
        this( null, mat4.diag(1), count );
    }

    this( SpaceNode p, mat4 m, size_t count )
    {
        spaceParent = p;
        initmtr = m;
        self_mtr = m;
        if( count <= 0 ) return;

        child ~= newEMM!DrawNode( this, calcChildTr0, count - 1 );
        child ~= newEMM!DrawNode( this, calcChildTr1, count - 1 );
        child ~= newEMM!DrawNode( this, calcChildTr2, count - 1 );
    }

    void draw( Camera cam )
    {
        drawSelf( cam.resolve(this.spaceParent), cam );
    }

    void rotate( vec3 rot, float k )
    {
        rotateSelf( rot );
        foreach( i, ch; child )
            ch.rotate( rot*k, k );
    }

    void setColors( vec4 c1, vec4 c2 )
    {
        if( c1 == scol1 && c2 == scol2 )
            return;

        scol1 = c1;
        scol2 = c2;

        color_changed = true;
        foreach( ref ch; child )
            ch.setColors( c1, c2 );
    }

protected:

    mat4 calcChildTr0()
    {
        auto q = quat.fromAngle( 1*3.14, vec3(1,0,0) );
        auto nm = quatAndPosToMatrix( q, vec3(0,0,0) );
        return mat4.diag(0.618).setCol(3,vec4(seg_len,0,0,1)) * nm;
    }

    mat4 calcChildTr1()
    {
        auto q = quat.fromAngle( 0.15, vec3(0,0,1) );
        auto nm = quatAndPosToMatrix( q, vec3(0,0,0) );
        return mat4.diag(0.9*0.618).setCol(3,vec4(seg_len * 0.381,.1,0,1)) * nm;
    }

    mat4 calcChildTr2()
    {
        auto q = quat.fromAngle( 0.01, vec3(0,1,0) );
        auto nm = quatAndPosToMatrix( q, vec3(0,0,0) );
        return nm;
    }

    vec2 calcChildRotCoef( size_t i )
    {
        return vec2(1,1);// / (i*0.5+1);
    }

    void rotateSelf( vec3 drot )
    {
        auto q0 = quat.fromAngle( drot.x, vec3(0,1,0) );
        auto q1 = quat.fromAngle( drot.y, vec3(0,0,1) );
        auto q2 = quat.fromAngle( drot.z * 0, vec3(1,0,0) );
        auto nm = quatAndPosToMatrix( q0 * q1 * q2, vec3(0,0,0) );
        self_mtr = initmtr * nm;
    }

    mat4 cached_matrix;

    void drawSelf( mat4 par_mtr, Camera cam )
    {
        if( color_changed )
        {
            shader.setUniform!vec4("col1", scol1);
            shader.setUniform!vec4("col2", scol2);
            color_changed = false;
        }

        cached_matrix = par_mtr * matrix;
        shader.setUniform!mat4( "prj", cam.projection.matrix * cached_matrix );
        drawArrays( DrawMode.TRIANGLES );

        foreach( ch; child )
            ch.drawSelf( cached_matrix, cam );
    }
}
