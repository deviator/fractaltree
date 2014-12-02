module yamlset;

public static import yaml;

import std.exception;
import std.string;
import std.typetuple;
import std.traits;

import des.math.linear;
import des.util.logger;

alias yaml.Node YAMLNode;

YAMLNode loadYAML( immutable(void[]) raw )
{ return yaml.Loader( raw.dup ).load(); }

immutable(void)[] dumpYAML( YAMLNode node )
{
    import std.stream;

    scope stream = new MemoryStream;
    auto dumper = yaml.Dumper(stream);
    dumper.dump( node );
    return stream.data.idup;
}

unittest
{
    auto yaml_str = `data: ok`;

    auto n1 = loadYAML( yaml_str.idup );

    auto bin1 = dumpYAML(n1);
    auto n2 = loadYAML(bin1);

    assert( n1 == n2 );
    assert( n1["data"].as!string == "ok" );
}

auto convYAML(T)( YAMLNode node )
{
    static if( is( T == YAMLNode ) ) return node;
    else static if( isVector!T || isMatrix!T )
    {
        T.datatype[] ret;
        enforce( node.isSequence );
        foreach( T.datatype val; node )
            ret ~= val;
        return T( ret );
    }
    else return node.as!T;
}

auto tryYAML(T=YAMLNode,K,string moduleName=__MODULE__,size_t line=__LINE__)( YAMLNode node, K key, T default_value=T.init )
{
    try
    {
        static if( is( K == string ) )
        {
            auto names = key.split(".");
            YAMLNode buf = node[names[0]];
            foreach( name; names[1..$] )
                buf = buf[name];
            return convYAML!T( buf );
        }
        else return convYAML!T( node[key] );
    }
    catch( Exception e )
        log_warn!(__MODULE__ ~ ".tryYAML")( "unable to get <%s> from YAML by key '%s' at %s:%d because: %s",
                typeid(T), key, moduleName, line, e.msg );

    return default_value;
}

@property string cacheName(T)() { return format( "%s_cache", T.mangleof ); }

private template tt(T){ alias T tt; }

@property string YAMLCacheElementCtor(string TypesName, Ts...)()
    if( Ts.length > 0 )
{
    string[] buf;
    foreach( i, tt; Ts )
        buf ~= format( "%s[%d][string] %s;", TypesName, i, cacheName!tt );
    return buf.join("\n");
}

@property bool readableFromYAML(T)()
{ return is( typeof( tryYAML!T( YAMLNode.init, "some", T.init ) ) ); }

struct YAMLCache(Types...)
    if( allSatisfy!( readableFromYAML, Types ) )
{
private:
    YAMLNode src;

    mixin( YAMLCacheElementCtor!("Types",Types) );

    bool updated = true;

public:

    void source( YAMLNode set )
    {
        updated = true;
        src = set;
    }

    void fix() { updated = false; }

    auto get(T)( string name, T def )
    {
        static if( staticIndexOf!(T,Types) == -1 )
            return tryYAML!T( src, name, def );
        else
        {
            if( updated || name !in mixin(cacheName!T) )
                mixin( cacheName!T )[name] = tryYAML!T( src, name, def );
            return mixin(cacheName!T)[name];
        }
    }
}

unittest
{
    auto yaml_str = `
        abc: 10
        cde: 12.0
        `;

    auto n1 = loadYAML( yaml_str.idup );

    YAMLCache!(int,float) cache;

    assert( cache.get!int( "abc", 3 ) == 3 );
    assert( cache.get!float( "cde", 3.0f ) == 3.0f );

    cache.source( n1 );

    assert( cache.get!int( "abc", 3 ) == 10 );
    assert( cache.get!float( "cde", 3.0f ) == 12.0f );

    cache.fix();

    assert( cache.get!int( "abc", 3 ) == 10 );
    assert( cache.get!float( "cde", 3.0f ) == 12.0f );

    assert( cache.get!int( "fff", 3 ) == 3 );
    assert( cache.get!int( "fff", 10 ) == 3 );
}
