create table bdd_field_table
(
    id_bdd_field_table integer NOT NULL,
    jid_bdd_table integer NOT NULL,
    field_name name,
    data_type varchar(100), 
    constraint bdd_field_table_pkey primary key (id_bdd_field_table)
);

alter table bdd_field_table
add column not_null varchar(10) default '';

alter table bdd_field_table
drop column not_null;

alter table bdd_field_table
add column default_constraint varchar(100) default '';

alter table bdd_field_table
add column check_constraint varchar(100) default '';

select t.table_name, f.* from bdd_field_table f 
join bdd_table t on t.id_bdd_table=f.jid_bdd_table
;

update bdd_field_table
set check_constraint=$$check (length(value) > 0)$$
where field_name in (
'data_type'
)

