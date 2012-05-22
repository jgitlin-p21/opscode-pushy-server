%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @copyright 2011-2012 Opscode Inc.

-module(pushy_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    case erlzmq:context() of
        {ok, Ctx} ->
            {ok, Pid} = pushy_sup:start_link(Ctx),
            {ok, Pid, Ctx};
        Error ->
            Error
    end.

stop(Ctx) ->
    erlzmq:term(Ctx, 5000).