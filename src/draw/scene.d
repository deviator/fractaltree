module draw.scene;

import des.util;
import des.gl;

import des.app.event;

import draw.tree;
import draw.camera;

import client;
import yamlset;
import std.math;

class Scene : ExternalMemoryManager
{
    mixin EMM;

protected:

    MCamera cam;
    Timer tm;

    Tree tree;

public:
    this()
    {
        tm = new Timer;
        cam = new MCamera;

        tree = newEMM!Tree;
    }

    void idle()
    {
        float dt = tm.cycle();
        tree.idle( dt );
    }

    void draw()
    {
        tree.draw( cam );
    }

    void keyControl( in KeyboardEvent ke )
    {
        cam.keyControl( ke );
    }

    void mouseControl( in MouseEvent me )
    {
        cam.mouseControl( me );
    }

    void resize( ivec2 sz )
    {
        cam.perspective.ratio = sz.x / cast(float)sz.y;
    }

    void setSettings( YAMLNode set )
    {
    }

    void updateClients( MClient[] clis )
    {
        if( clis.length > 0 )
        {
            tree.orient = clis[0].orient / 180.0 * PI;
            tree.rotcoef = clis[0].p1 / 100.0f;

            auto pos = clis[0].pos;

            static const need_angle1 = 0.666 * PI;
            static const need_angle2 = 1.333 * PI;
            static const need_angle3 = 2.0 * PI;

            static vec2 prev_pos;

            if( prev_pos == pos )
            {
                prev_pos = pos;
                return;
            }

            col4 color;
            color.a = 1.0;

            float fangle, sangle;

            import std.math;

            auto angle = atan2( pos.y, pos.x ) + PI;

            if( angle >= 0 && angle < need_angle1 )
            {
                fangle = 1 - angle / need_angle1;
                sangle = 1 - fangle;
                color.r = fangle;
                color.g = sangle;
            }
            else if( angle >= need_angle1 && angle < need_angle2 )
            {
                fangle = 1 - ( angle - need_angle1 ) / need_angle1;
                sangle = 1 - fangle;
                color.g = fangle;
                color.b = sangle;
            }
            else if( angle >= need_angle2 && angle < need_angle3 )
            {
                fangle = 1 - ( angle - need_angle2 ) / need_angle1;
                sangle = 1 - fangle;
                color.b = fangle;
                color.r = sangle;
            }
            
            tree.setColors( color, col4( 1,0,0,1 ) );
        }
    }
}
