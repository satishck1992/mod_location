%% name of module must match file name
-module(mod_location).

%% Every ejabberd module implements the gen_mod behavior
%% The gen_mod behavior requires two functions: start/2 and stop/1
-behaviour(gen_mod).

%% public methods for this module
-export([start/2, stop/1]).
-export([on_user_send_packet/3]).

%% included for writing to ejabberd log file
-include("ejabberd.hrl").
-include("logger.hrl").

%% ejabberd functions for JID manipulation called jlib.
-include("jlib.hrl").
%%add and remove hook module on startup and close

start(Host, _Opts) ->
    ejabberd_hooks:add(filter_packet, global, ?MODULE, on_user_send_packet, 0).

stop(Host) ->
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_user_send_packet, 0),
    ok.

on_user_send_packet(From, To, Packet) ->
    ?INFO_MSG(" Hello World ", []),
    Type = xml:get_tag_attr_s(<<"type">>,Packet),
    case Type of
        <<"location">> ->
            record_location(From, Packet),
            drop;
        _ ->
            Packet
    end.

record_location(From, Packet) ->
    Location = xml:get_subtag(Packet, <<"location">>),
    Lat = xml:get_tag_attr_s(<<"lat">>, Location),
    Long = xml:get_tag_attr_s(<<"long">>, Location),
    Database = gen_mod:get_opt(odbc_database, []),
    Host = gen_mod:get_opt(odbc_server, []),
    Username = gen_mod:get_opt(odbc_username, []),
    Password = gen_mod:get_opt(odbc_password, []),
    [Name|Tail] = string:tokens(From, "@"),
    {ok, Db} = pgsql:connect(Database, Host, Username, Password),  
    pgsql:squery(Db, " UPDATE users " ++
                    " SET users.lat = " ++ Lat ++ ", " ++
                    " users.long = " ++ Long ++
                    " WHERE users.username = '" ++ Name ++ "'").