create table ml (
	ml      char(64),
	file    char(64),
	address char(64),
	off     int,
	options char(64)
);

insert into ml
values ('elena', 'actives', 'fukachan@sapporo.iij.ad.jp', 0, '');
insert into ml
values ('elena', 'members', 'fukachan@sapporo.iij.ad.jp', 0, '');

insert into ml
values ('elena', 'actives', 'fukachan@fml.org', 0, '');
insert into ml
values ('elena', 'members', 'fukachan@fml.org', 0, '');


select * from ml ;

select * from ml 
	where address = 'kenken@nuinui.net'
		and
	file = 'actives' ;

select * from ml 
	where address = 'fukachan@nuinui.net'
		and
	file = 'actives' ;
