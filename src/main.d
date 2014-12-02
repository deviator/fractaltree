module main;

import core.thread;

import des.flow;
import des.util.emm;
import des.util.logger;
import des.util.helpers;

import yamlset;
import fthandler;

import draw.we;
import sock.we;

WorkElement createWE(T)( immutable(void)[] set )
    if( is( T : WorkElement ) )
{ return new T( loadYAML(set) ); }

FThread[] prepare( string cfg_fn )
{
    auto root = yaml.Loader( cfg_fn ).load();

    auto draw_set = dumpYAML( root["draw"] );
    auto sock_set = dumpYAML( root["sock"] );

    auto draw = new FThread( "draw", &(createWE!DrawWE), draw_set );
    auto sock = new FThread( "sock", &(createWE!SockWE), sock_set );

    sock.addListener( draw );
    return [ draw, sock ];
}

void main()
{
    auto cfg_fn = appPath( "..", "data", "cfg.yaml" );
    auto sys = new FTHandler( cfg_fn, prepare( cfg_fn ) );

    log_info( "app start" );

    sys.pushCommand( Command.START );
    while( sys.check )
        Thread.sleep(dur!"msecs"(100));

    log_info( "app finish" );

    scope(exit)
    {
        sys.pushCommand( Command.CLOSE );
        sys.join();
        sys.destroy();
    }
}
