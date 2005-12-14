<!--
   $FML: ml.hier.ml,v 1.2 2004/04/07 11:07:02 fukachan Exp $

   階層化されたＭＬ: $member_maps $recipient_maps をよろしく書く

-->

<sect1 id="config.hier.ml">
	<title>
	ケーススタディ: ＭＬの階層化
	</title>

<para>
メンバー制限をする普通の ML 群を考えます。
(fml bible にあるように)例えば営業部に営業 1、 2、 3 課がある場合です。
</para>

<para>
まず、それぞれの課用に sales-1、 sales-2、 sales-3 ML を作り、
 ML のメンバーはそれぞれの課で管理してもらうことにします。
また別途、営業部全体の連絡用に sales  ML も作り、
sales ML へメールを送信すると、
sales-1 sales-2 sales-3 のメンバーにも配送されます。
</para>

<para>
配送先は sales ＭＬの config.cf で
<screen>
recipient_maps 	+=	$ml_home_dir/../sales-1/recipients
recipient_maps 	+=	$ml_home_dir/../sales-2/recipients
recipient_maps 	+=	$ml_home_dir/../sales-3/recipients
</screen>
とすれば、sales-1,2,3 すべてのメンバーに配送されます。
</para>

<para>
投稿可能なメンバーも同様に
<screen>
member_maps 	+=	$ml_home_dir/../sales-1/members
member_maps 	+=	$ml_home_dir/../sales-2/members
member_maps 	+=	$ml_home_dir/../sales-3/members
</screen>
としてください。
社内用の場合はか、member_maps を変更せずとも
誰でも投稿できるように
<screen>
article_post_restrictions	=	permit_anyone
</screen>
と設定してしまうのもアリでしょう。
</para>

<para>
ここではファイルで管理する例を取り上げています。
これは簡単で、すぐに実行できるというのがよいところです。
</para>

<para>
しかしながら、MySQL なりで組織図とメール配送のリストを管理するほうが現
代的ではあるでしょう。準備も保守も、それなりに必要となりますが
</para>

</sect1>
