module sock.we;

import std.file;

import des.flow;
import des.util.logger;

import std.socket;
import std.socketstream;

import des.math.linear;

import yamlset;
import code;

class SockWE : WorkElement, EventProcessor
{
private:
    Socket sock;
    string sock_file;

public:
    this( YAMLNode set )
    {
        sock_file = tryYAML!string( set, "file", "/tmp/ftree.sock" );
        if( sock_file.exists ) remove( sock_file );

        sock = new Socket( AddressFamily.UNIX, SocketType.STREAM );
        sock.bind( new UnixAddress( sock_file ) );
        sock.listen(20);
    }

    override void process()
    {
        Socket cli;
        try cli = sock.accept();
        catch( SocketAcceptException sae ) return;
        catch( Exception e ) throw e;

        auto data = new void[](2048);
        auto dsize = cli.receive( data );
        cli.close();
        logger.Debug( dsize );
        if( dsize <= 0 ) return;
        logger.Debug( cast(char[])(data[0 .. dsize]) );

        //pushEvent( Event( EvCode.USER, current_users ) );
        //logger.trace( "pass" );
    }

    void processEvent( in Event ev )
    {
    }

    override EventProcessor[] getEventProcessors() { return [this]; }

    protected void selfDestroy()
    {
        sock.shutdown( SocketShutdown.BOTH );
        sock.close();
        remove( sock_file );
    }
}
