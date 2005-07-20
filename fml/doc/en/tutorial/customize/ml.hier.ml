<!--
   $FML: ml.hier.ml,v 1.1 2003/08/02 01:19:10 fukachan Exp $
   $jaFML: ml.hier.ml,v 1.1 2002/07/29 12:16:19 fukachan Exp $

-->

<sect1 id="config.hier.ml">
	<title>
	case study: hierarchical ML
	</title>

<para>
Consider usual ML's which allows post from registered members.
For example, sales 1, 2 and 3 division.
</para>

<para>
Create sales-1, sales-2 and sales-3 ML.
Each division manages each member list.
Also, create sales ML other than that to inform the whole sales members.
If you send a mail to sales ML, the mail is sent to all members of
sales-1, sales-2 and sales-3 ML.
</para>

<para>
Define the following $recipient_maps in the config.cf of sales ML.
<screen>
recipient_maps 	+=	$ml_home_dir/../sales-1/recipients
recipient_maps 	+=	$ml_home_dir/../sales-2/recipients
recipient_maps 	+=	$ml_home_dir/../sales-3/recipients
</screen>
</para>

<para>
Define $member_maps in the same way to allow post from all sales
members:
<screen>
member_maps 	+=	$ml_home_dir/../sales-1/members
member_maps 	+=	$ml_home_dir/../sales-2/members
member_maps 	+=	$ml_home_dir/../sales-3/members
</screen>
Instead of $member_maps change, it is simple that you allow post from
anybody. If so set
<screen>
post_restrictions	=	permit_anyone
</screen>
</para>

<para>
This example is simplest. It is easy to use this style.
</para>

<para>
If you need to use SQL e.g. MySQL, it is modern. 
It needs a lot of preparions and operation know-how.
</para>

</sect1>
