		インストールについて

  * 用語について:
	% 一般ユーザのプロンプト
	# ユーザ root のプロンプト
	fml 4 ( fml 4.0 シリーズのこと )


対話型インストーラなどは"まだ"作られていません。

トップ・ディレクトリにある INSTALL.sh の先頭にあるディレクトリ名などを
適当に修正し、root で実行して下さい。

	% su root
	# sh INSTALL.sh

それぞれのディレクトリの役割は次の通りです。

/etc/fml

	基本設定ファイルを置く場所。
	( fml 4 の /usr/local/fml/.fml や default_config.ph 相当)

	バージョンやライブラリの場所(ディレクトリ)などを指定する。


/usr/local/libexec/fml

	実行ファイル ( fml 4 の /usr/local/fml )


/usr/local/lib/fml

	ライブラリ ( fml 4 の /usr/local/fml )


/var/spool/ml

	ＭＬのホームディレクトリ。fml 4 と同じ目的です。

	注意: /var/spool/ml のオーナは INSTALL.sh の
	owner 変数(デフォルトはユーザ fml)に設定されます。


○ ドキュメントは HTML 版だけです。

トップ・ディレクトリにある index.ja.html からたどっていってください。


○ elena ＭＬの設定の見方

   全部の変数を表示する
	/usr/local/libexec/fml/fmlconf elena

   デフォルト値と異なる変数を表示する
	/usr/local/libexec/fml/fmlconf -n elena
