module fthandler;

import des.flow;
import des.util.emm;
import des.util.logsys;
import code;
import yamlset;

class FTHandler: ExternalMemoryManager
{
    mixin ParentEMM;

    string config_file_name;
    FThread[] list;

    this( string fn, FThread[] list )
    {
        config_file_name = fn;
        this.list = registerChildsEMM(list);
    }

    @property bool check()
    {
        foreach( th; list )
        {
            foreach( sig; th.takeAllSignals() )
            {
                auto sigcode = cast(SigCode)sig.code;
                final switch( sigcode )
                {
                    case SigCode.QUIT:
                        pushCommand( Command.CLOSE );
                        return false;
                    case SigCode.RELOADSETTING:
                        reloadSettings();
                        break;
                }
            }
            if( th.info.error != FThread.Error.NONE )
            {
                logger.error( "'%s' has error [%s] at time [%016.9f] : %s",
                        th.name, th.info.error, th.info.timestamp / 1e9f,
                        th.info.message );
                pushCommand( Command.CLOSE );
                return false;
            }
        }
        return true;
    }

    void pushCommand( Command cmd )
    { foreach( th; list ) th.pushCommand( cmd ); }

    void join() { foreach( th; list ) th.join(); }

    void reloadSettings()
    {
        auto root = yaml.Loader( config_file_name ).load();

        foreach( th; list )
        {
            auto sdump = dumpYAML( root[th.name] );
            th.pushEvent( Event( EvCode.SETTING, sdump ) );
        }
    }
}
