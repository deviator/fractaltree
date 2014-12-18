module draw.window;

static import des.flow;

alias des.flow.Event FEvent;
alias des.flow.SysEvData SysEvData;
alias des.flow.SignalBus SignalBus;

import des.app;
import des.util.stdext.algorithm;
import des.util.logsys;

import yamlset;
import code;
import client;

import draw.scene;

class MainWindow : GLWindow, des.flow.EventProcessor
{
private:
    Scene scene;

protected:

    YAMLNode setting;
    SignalBus sigbus;

    override void prepare()
    {
        scene = newEMM!Scene;

        connect( idle, &(scene.idle) );
        connect( draw, &(scene.draw) );
        //connect( key, &(scene.keyControl) );
        connect( mouse, &(scene.mouseControl) );
        connect( resized, &(scene.resize) );
    }

public:

    this( string title, ivec2 sz, bool fullscreen = false )
    { super( title, sz, fullscreen ); }

    this( SignalBus sigbus, YAMLNode set )
    {
        if( set.containsKey("window") )
        {
            auto ws = set["window"];
            auto title = tryYAML!string( ws, "title", "fractaltree" );
            auto sz = tryYAML!ivec2( ws, "size", ivec2(800,600) );
            auto fs = tryYAML!bool( ws, "fullscreen", false );
            super( title, sz, fs );
        }
        else super( "nsdr", ivec2(800,600), false );

        if( set.containsKey("scene") )
            this.setting = set["scene"];

        this.sigbus = sigbus;
    }

    void processEvent( in FEvent ev )
    {
        switch( ev.code )
        {
            case EvCode.SETTING:
                auto set = loadYAML( ev.pdata );
                if( set.containsKey("scene") )
                    scene.setSettings( set["scene"] );
                break;
            case EvCode.MCLIENT:
                scene.updateClients( [ev.data.as!MClient] );
                break;

            case FEvent.system_code:
                if( scene is null ) break;
                auto sysev = ev.as!SysEvData;
                //scene.work = sysev.isWork;
                break;
            default:
                break;
        }
    }
}
