module sock.we;

import std.file;

import des.flow;
import des.util.logger;

import std.socket;
import std.socketstream;

import des.math.linear;

import yamlset;
import code;
import client;

class SockWE : WorkElement, EventProcessor
{
private:
    Socket sock;
    string sock_file;
    void[] buffer;

public:
    this( YAMLNode set )
    {
        sock_file = tryYAML!string( set, "file", "/tmp/ftree.sock" );
        if( sock_file.exists ) remove( sock_file );

        sock = new Socket( AddressFamily.UNIX, SocketType.STREAM );
        sock.bind( new UnixAddress( sock_file ) );
        sock.listen(20);
        buffer = new void[]( tryYAML!uint( set, "maxbuflen", 4096U ) );
    }

    override void process()
    {
        Socket cli_sock = tryAcceptSocket();
        if( cli_sock is null ) return;

        auto dsize = cli_sock.receive( buffer );
        cli_sock.close();
        if( dsize <= 0 ) return;

        parseInput( buffer[0..dsize] );
        emitEvents();
    }

    void processEvent( in Event ev ) { }

    override EventProcessor[] getEventProcessors() { return [this]; }

protected:

    void selfDestroy()
    {
        stopSock();
    }

    void stopSock()
    {
        sock.shutdown( SocketShutdown.BOTH );
        sock.close();
        remove( sock_file );
    }

    Socket tryAcceptSocket()
    {
        Socket ret;
        try ret = sock.accept();
        catch( SocketAcceptException sae ) return null;
        catch( Exception e ) throw e;
        return ret;
    }

    MClient cur_cli;
    bool cur_cli_updated = false;

    void parseInput( void[] data )
    {
        cur_cli_updated = false;

        import std.json;
        import std.conv;

        JSONValue root;

        try root = parseJSON( cast(char[])data );
        catch( Exception e )
        {
            logger.error( "json parse error: %s", e.msg );
            return;
        }

        try
        {
            auto jd = root["mobclient"];

            cur_cli.id = to!size_t(jd["id"].str);

            cur_cli.orient[0] = to!float(jd["orient"][0].str);
            cur_cli.orient[1] = to!float(jd["orient"][1].str);
            cur_cli.orient[2] = to!float(jd["orient"][2].str);

            cur_cli.motion[0] = to!float(jd["motion"][0].str);
            cur_cli.motion[1] = to!float(jd["motion"][1].str);
            cur_cli.motion[2] = to!float(jd["motion"][2].str);

            cur_cli.p1 = to!float(jd["slider"].str);
        }
        catch( Exception e )
        {
            logger.error( "bad json: %s", e.msg );

            try
            {
                auto jd = root["mobclient"];
                logger.Debug( "id: %s", jd["id"] );
                logger.Debug( "orient: [%s,%s,%s]", jd["orient"][0], jd["orient"][1], jd["orient"][2] );
                logger.Debug( "motion: [%s,%s,%s]", jd["motion"][0], jd["motion"][1], jd["motion"][2] );
                logger.Debug( "slider: %s", jd["slider"] );
            }
            catch( Exception e )
                logger.error( "debug out fails: %s", e.msg );
        }

        logger.Debug( cur_cli );
        cur_cli_updated = true;
    }

    void emitEvents()
    {
        if( cur_cli_updated )
            pushEvent( Event( EvCode.MCLIENT, cur_cli ) );
    }
}
