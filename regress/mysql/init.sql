create table ml (
	fml_ml        char(64),
	fml_domain    char(64),
	fml_address   char(64),
	fml_member    int,
	fml_recipient int
);

insert into ml
values ('elena', 'fml.org', 'fukachan@sapporo.iij.ad.jp',	1, 1);

insert into ml
values ('elena', 'fml.org', 'fukachan@fml.org', 		1, 1);


select * from ml ;


select fml_address from ml
	where fml_ml = 'elena'
		and
		fml_domain = 'fml.org'
		and
	fml_recipient = 1;


update ml set fml_recipient = 0
	where fml_ml = 'elena'
		and
		fml_domain = 'fml.org'
		and
	fml_address  = 'fukachan@fml.org';


select * from ml ;


select fml_address from ml
	where fml_ml = 'elena'
		and
		fml_domain = 'fml.org'
		and
	fml_recipient = 1;

