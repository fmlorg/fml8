-module(test1).
-export([test/0]).

test() ->
  io:format("~n"),
  test_1(),
  test_char(),
  test_deeplist(),
  ok.

test_1_sub(Name,Fun) ->
  io:format("~s ...~n", [Name]),
  Ret = Fun(),
  io:format("~s: ~p~n", [Name, Ret]),
  Ret.

test_1() ->
  io:format("test_1: ...~n"),
  test_1_sub(start, fun()-> unijp:start() end),
  test_1_sub(version_str,   fun()-> unijp:version_str()                end),
  test_1_sub(version_tuple, fun()-> unijp:version_tuple()              end),
  test_1_sub(conv,          fun()-> unijp:conv("utf8", "utf8", "text") end),
  test_1_sub(conv,          fun()-> unijp:conv("utf8", "ucs4", "ts") end),
  test_1_sub(conv,          fun()-> unijp:conv("utf8", "ucs4", "text") end),
  io:format("- ok.~n~n"),
  ok.

test(FromCode, ToCode) ->
  FromText = get(FromCode),
  ToText   = get(ToCode),
  io:format("~p -> ~p ...", [FromCode, ToCode]),
  Ret = unijp:conv(FromCode, ToCode, FromText),
  case Ret of
  ToText -> io:format(" ok # ~p:~w -> ~p:~w~n", [FromCode, FromText, ToCode, Ret]);
  _      -> io:format(" not ok ~p~n", [Ret])
  end.

test_char() ->
  io:format("test_char: ...~n"),
  % U+611B, kanji, ai (love).
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

  io:format("- ok.~n~n"),
  ok.

test_deeplist() ->
  io:format("test_deeplist: ...~n"),
  Data =  [
    <<"XXXXXXXXXXXXXX1" >>,
    <<"\t">>,
    <<",,,,,,,,,,,,,,,,,,,,,,,,,,,">>
  ],
  Ret = unijp:conv(utf8, sjis, Data),
  case Ret == binary_to_list(iolist_to_binary(Data)) of
  true  -> io:format("ok~n");
  false -> io:format("not ok~n")
  end,
  io:format("~n"),
  ok.
