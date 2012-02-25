-module(test1).
-export([test/0]).

test(FromCode, ToCode) ->
  FromText = get(FromCode),
  ToText   = get(ToCode),
  io:format("~p -> ~p ...", [FromCode, ToCode]),
  Ret = unijp:conv(FromCode, ToCode, FromText),
  case Ret of
  ToText -> io:format(" ok # ~p:~w -> ~p:~w~n", [FromCode, FromText, ToCode, Ret]);
  _      -> io:format(" not ok ~p~n", [Ret])
  end.

test() ->
  put(utf8,  [16#e6, 16#84, 16#9b]),
  put(sjis,  [16#88, 16#a4]),
  put(eucjp, [16#b0, 16#a6]),
  put(jis,   "\e$B0&\e(B"),
  put(ucs2,  [16#61, 16#1b]),
  put(ucs4,  [0, 0, 16#61, 16#1b]),

  unijp:start(),

  test(utf8, utf8),
  test(utf8, sjis),
  test(utf8, eucjp),
  test(utf8, jis),
  test(utf8, ucs2),
  test(utf8, ucs4),

  test(utf8,  utf8),
  test(sjis,  utf8),
  test(eucjp, utf8),
  test(jis,   utf8),
  test(ucs2,  utf8),
  test(ucs4,  utf8),

  unijp:stop(),
  ok.


