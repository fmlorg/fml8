<!--
   $FML$

   ���ز����줿�ͣ�: $member_maps $recipient_maps ��������

-->

<sect1 id="config.hier.ml">
	<title>
	�����������ǥ�: �̤ͣγ��ز�
	</title>

<para>
���С����¤򤹤����̤� ML ����ͤ��ޤ���
(fml bible �ˤ���褦��)�㤨�бĶ����˱Ķ� 1�� 2�� 3 �ݤ�������Ǥ���
</para>

<para>
�ޤ������줾��β��Ѥ� sales-1�� sales-2�� sales-3 ML ���ꡢ
 ML �Υ��С��Ϥ��줾��βݤǴ������Ƥ�餦���Ȥˤ��ޤ���
�ޤ����ӡ��Ķ������Τ�Ϣ���Ѥ� sales  ML ���ꡢ
sales ML �إ᡼�����������ȡ�
sales-1 sales-2 sales-3 �Υ��С��ˤ���������ޤ���
</para>

<para>
������� sales �̤ͣ� config.cf ��
<screen>
recipient_maps 	+=	$ml_home_dir/../sales-1/recipients
recipient_maps 	+=	$ml_home_dir/../sales-2/recipients
recipient_maps 	+=	$ml_home_dir/../sales-3/recipients
</screen>
�Ȥ���С�sales-1,2,3 ���٤ƤΥ��С�����������ޤ���
</para>

<para>
��Ʋ�ǽ�ʥ��С���Ʊ�ͤ�
<screen>
member_maps 	+=	$ml_home_dir/../sales-1/members
member_maps 	+=	$ml_home_dir/../sales-2/members
member_maps 	+=	$ml_home_dir/../sales-3/members
</screen>
�Ȥ��Ƥ���������
�����Ѥξ��Ϥ���member_maps ���ѹ������Ȥ�
ï�Ǥ���ƤǤ���褦��
<screen>
post_restrictions	=	permit_anyone
</screen>
�����ꤷ�Ƥ��ޤ��Τ⥢��Ǥ��礦��
</para>

</sect1>
