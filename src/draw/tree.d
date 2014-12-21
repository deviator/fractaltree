module draw.tree;

import des.util;
import des.gl;
import des.view;
import std.math;

import draw.object;

import std.algorithm;

struct TimeMeasure
{
    float[] tm;

    size_t cur;
    size_t max_cnt = 10;

    this( size_t max_cnt ) { this.max_cnt = max_cnt; }

    void append( float t )
    {
        if( tm.length < max_cnt ) tm ~= t;
        else tm[cur++%tm.length] = t;
    }

    @property float avg() const
    {
        if( tm.length == 0 ) return 0;
        return sum(tm) / tm.length;
    }
}

class Tree : ExternalMemoryManager
{
    mixin EMM;
    mixin ClassLogger;
protected:

    DrawNode master;
    Timer tm;

    float k = 0;
    TimeMeasure meas;

public:

    this()
    {
        master = newEMM!DrawNode( 6 );
        tm = new Timer;
    }

    void idle( float dt )
    {
        k+=dt;
        logger.trace( orient, rotcoef );
        master.rotate( orient, rotcoef );
        logger.trace( meas.avg );
    }

    vec3 orient = vec3(0,0,0);
    float rotcoef = 1;

    void setColors( col4 c1, col4 c2 )
    { master.setColors( c1, c2 ); }

    void draw( Camera cam )
    {
        tm.reset();

        master.draw( cam );
        meas.append( tm.cycle() );
    }

protected:

}
