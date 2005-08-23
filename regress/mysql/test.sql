
insert into ml
values ('elena', 'home.fml.org', 'fukachan@sapporo.iij.ad.jp',	1, 1);

insert into ml
values ('elena', 'home.fml.org', 'fukachan@home.fml.org',	1, 1);


select * from ml ;


select fml_address from ml
	where fml_ml = 'elena'
		and
		fml_domain = 'home.fml.org'
		and
	fml_recipient = 1;


update ml set fml_recipient = 0
	where fml_ml = 'elena'
		and
		fml_domain = 'home.fml.org'
		and
	fml_address  = 'fukachan@home.fml.org';


select * from ml ;


select fml_address from ml
	where fml_ml = 'elena'
		and
		fml_domain = 'home.fml.org'
		and
	fml_recipient = 1;

