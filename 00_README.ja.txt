○ インストール

ちゃんとしたインストーラはまだありません。

トップ・ディレクトリにある INSTALL.sh の先頭にあるディレクトリ名などを
適当に修正し、root で実行して下さい。

	% su root
	# sh INSTALL.sh

それぞれのディレクトリの役割は次の通りです。

/etc/fml

	基本設定ファイル
	( fml 4 の /usr/local/fml/.fml や default_config.ph 相当)

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
