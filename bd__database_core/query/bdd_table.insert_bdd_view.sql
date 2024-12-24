
insert into bdd_field_table (id_bdd_field_table, jid_bdd_table, field_name, data_type, not_null, default_constraint, check_constraint)
values
(bdc_random_int(), 1494496930,'id_bdd_view','integer', 'not null', '', ''),
(bdc_random_int(), 1494496930,'view_name','name', 'not null', '', ''),
(bdc_random_int(), 1494496930,'notes','text', 'not null', 'default ''''::text', '')
;


insert into bdd_field_table (id_bdd_field_table, jid_bdd_table, field_name, data_type, not_null, default_constraint, check_constraint)
values
(bdc_random_int(), 1494496930,'source_code','text', 'not null', '', '');

select "bdd_table.migrate"('bdd_view');