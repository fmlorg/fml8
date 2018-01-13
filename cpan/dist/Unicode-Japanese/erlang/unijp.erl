% -----------------------------------------------------------------------------
% unijp.erl
% -----------------------------------------------------------------------------
% Mastering programmed by YAMASHINA Hio
%
% Copyright 2007 YAMASHINA Hio
% -----------------------------------------------------------------------------

% -----------------------------------------------------------------------------
%% @author    YAMASHINA Hio <hio@hio.jp>
%% @copyright 2008 YAMASHINA Hio
%% @version   0.01
%% @doc       Unicode::Japanese binding
%% == SUPPORTED ENCODINGS ==
%% These options are available for `Icode' argument of {@link new/3} and {@link set/2}.
%% <ul>
%% <li>`utf8'</li>
%% <li>`sjis'</li>
%% <li>`eucjp'</li>
%% <li>`jis'</li>
%% </ul>
%% @end
% -----------------------------------------------------------------------------

-module(unijp).
-export([start/0, stop/0]).
-export([version_str/0]).
-export([version_tuple/0]).
-export([conv/3]).
-export([test/0]).

-define(SHAREDLIB, "unijp_driver").
-define(PKGNAME, unijp).
-define(REGNAME, unijp).

-define(PORT_VERSION_STR,   1).
-define(PORT_VERSION_TUPLE, 2).
-define(PORT_CONV_3,        3).

test(Name,Fun) ->
  io:format("~s ...~n", [Name]),
  Ret = Fun(),
  io:format("~s: ~p~n", [Name, Ret]),
  Ret.
test() ->
  test(start, fun()-> start() end),
  test(version_str,   fun()-> version_str()                end),
  test(version_tuple, fun()-> version_tuple()              end),
  test(conv,          fun()-> conv("utf8", "utf8", "text") end),
  test(conv,          fun()-> conv("utf8", "ucs4", "ts") end),
  test(conv,          fun()-> conv("utf8", "ucs4", "text") end),
  io:format("ok.~n"),
  ok.

% -----------------------------------------------------------------------------
% version_str().
%% @spec version_str() -> string()
%% @doc get version number as string.
version_str() ->
	Result = erlang:port_call(whereis(?REGNAME), ?PORT_VERSION_STR, []),
	{ok, VersionStr} = Result,
	VersionStr.

% -----------------------------------------------------------------------------
% version_tuple().
%% @spec version_tuple() -> {int(),int(),int()}
%% @doc get version number as tuple of integers.
version_tuple() ->
	Result = erlang:port_call(whereis(?REGNAME), ?PORT_VERSION_TUPLE, []),
	{ok, {Major,Minor,Patch}} = Result,
	{Major,Minor,Patch}.

% -----------------------------------------------------------------------------
% conv(From, To, Source).
%% @spec conv(From, To, Source) -> string()
%%   From   = atom()
%%   To     = atom()
%%   Source = iolist()
%% @doc convert string Source from From to To.
conv(From, To, Source) ->
	Bin = iolist_to_binary(Source),
	Result = erlang:port_call(whereis(?REGNAME), ?PORT_CONV_3, {From,To,Bin}),
	{ok, Converted} = Result,
	Converted.

% -----------------------------------------------------------------------------
% start.
%
%% @spec start()->term()
%% @doc  start port driver
start() ->
	my_start(whereis(?REGNAME)).

%% @spec my_start(Port)->pod()
%%   Port = undefined | port()
%% @private
my_start(undefined) ->
	% io:format("start: begin trans..~n"),
	global:trans({unijp_start, self()}, fun()->
		case whereis(?REGNAME) of
		undefined ->
			% io:format("start: real start~n"),
			Pid = my_spawn_server(),
			% io:format("start: register: ~p (registered:~p)~n", [Pid, whereis(?REGNAME)]),
			Pid;
		Pid ->
			% io:format("start: found in tran ~p~n", [Pid]),
			Pid
		end
	end);
my_start(Pid) ->
	% io:format("start: exists: ~p~n", [Pid]),
	Pid.

%% @spec my_spawn_server()->pid()
%% @private
%% @doc  spawn server process.
my_spawn_server() ->
	% io:format("spawn server ...~n"),
	Parent = self(),
	Daemon = spawn(fun()->my_server(Parent) end),
	Port = receive
		{Daemon, Recv} -> Recv
		% after 3000     -> exit(timeout)
		after 3000*60     -> exit(timeout)
	end,
	Port.

%% @spec my_server(Parent)->void()
%%   Parent = pid()
%% @private
%% @doc  unijp daemon, main.
my_server(Parent) ->
	% io:format("server proc ...~n"),
	Port = my_open_port(),
	register(?REGNAME, Port),
	register(unijp_daemon, self()),
	Parent ! {self(), Port},
	my_server_loop([]).

%% @spec my_open_port() -> port()
%% @private
%% @doc  open port procedure.
my_open_port()->
	% io:format("load_driver ...~n"),
	case erl_ddll:load_driver(code:priv_dir(?PKGNAME), ?SHAREDLIB) of
		ok -> ok;
		{error, already_loaded} -> ok;
		Any -> exit({error, {could_not_load_driver, Any}})
	end,
	% io:format("open_port ...~n"),
	Port = open_port({spawn, ?SHAREDLIB}, [binary]),
	% io:format("open_port ~p on ~p~n", [Port, self()]),
	Port.

%% @spec my_server_loop(PortList)->void()
%%   PortList = [port()]
%% @private
%% @doc  loop forever to keep driver/port instances.
my_server_loop(PortList)->
	% io:format("my_server_loop ~p(~p)~n", [self(), PortList]),
	receive
	{ Caller, close } when is_pid(Caller) ->
		Caller ! ok;
	{ Caller, find_port } when is_pid(Caller) ->
		my_server_find_port(Caller, PortList);
	{ Caller, release_port, Port } when is_pid(Caller) ->
		my_server_loop([Port|PortList]);
	_Any ->
		my_server_loop(PortList)
	end.

my_server_find_port(Caller, []) ->
	my_server_find_port(Caller, [my_open_port()]);
my_server_find_port(Caller, [Port|PortList]) ->
	Caller ! { find_port, Port },
	my_server_loop(PortList).

% -----------------------------------------------------------------------------
% stop.
%
%% @spec stop() -> ok
%% @doc  stop unijp port service.
stop() ->
	case whereis(unijp_daemon) of
	undefined ->
		ok;
	Port ->
		Port ! { self(), close },
		receive
			ok -> ok
		after 10000 ->
			exit(noreply)
		end
	end.

% -----------------------------------------------------------------------------
% End of Module.
% -----------------------------------------------------------------------------
