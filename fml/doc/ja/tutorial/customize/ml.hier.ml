<!--
   $FML$

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
post_restrictions	=	permit_anyone
</screen>
と設定してしまうのもアリでしょう。
</para>

</sect1>
