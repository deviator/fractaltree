module draw.scene;

import des.util;
import des.gl;

import des.app.event;

import draw.tree;
import draw.camera;

class Scene : ExternalMemoryManager
{
    mixin ParentEMM;

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
}
