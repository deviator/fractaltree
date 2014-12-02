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
    mixin ParentEMM;
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
        master.rotate( deltaAngle(dt) );
        log_trace( meas.avg );
    }

    void draw( Camera cam )
    {
        tm.reset();
        master.draw( cam );
        meas.append( tm.cycle() );
    }

protected:

    @property vec2 deltaAngle( float dt )
    {
        return vec2( sin( k * 0.05 ), cos( k * 0.1 ) );
    }
}
