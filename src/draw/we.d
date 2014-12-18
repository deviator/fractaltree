module draw.we;

import des.flow;
import des.util.logsys;
import des.app;

import yamlset;
import code;

import draw.window;

class DrawWE : WorkElement
{
    GLApp app;
    MainWindow win;
    bool quitsig = false;

    this( YAMLNode set )
    {
        logger = new InstanceLogger( this );

        app = newEMM!GLApp;
        app.addWindow({ return win = new MainWindow(this,set); });
    }

    override void process()
    {
        if( quitsig ) return;

        if( app.isRuning && app.step() )
            logger.trace( "app work" );
        else quit();
    }

    void quit()
    {
        logger.info( "app quit" );
        sendSignal( des.flow.Signal(SigCode.QUIT) );
        quitsig = true;
    }

    override des.flow.EventProcessor[] getEventProcessors() { return [win]; }
    protected override void selfDestroy() { logger.info( "pass" ); }
}

