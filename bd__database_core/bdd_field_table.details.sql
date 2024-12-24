create or replace view "bdd_field_table.details"
as
-- more details for field definitions are used to compare with the postgres definition
-- select * from "bdd_field_table.details" ;

select t.table_name, f.field_name, 
-- data_type
f.data_type,
f.data_type as data_type_formatted,
case when c.data_type='character varying' then format('varchar(%s)', c.character_maximum_length)
else c.data_type
end as bdc_data_type_formatted,
-- not null
f.not_null,
f.not_null as not_null_formatted, 
case when c.is_nullable='YES' then ''
else 'not null'
end as bdc_is_nullable_formatted,
-- default constraint
f.default_constraint,
case 
    when f.default_constraint='' then ''
    else format('%s',bdc_strip_prefix(f.default_constraint,'default '))
end as default_constraint_formatted,
replace(replace(coalesce(c.column_default,''), '::character varying', ''),'::text','') as bdc_column_default_formatted,
-- check constraint
f.check_constraint,
case 
    when f.check_constraint='' then ''
    else format('(%s)',bdc_strip_prefix(f.check_constraint,'check '))
end as check_constraint_formatted,
coalesce(c.check_clause,'') as bdc_check_clause_formatted,
c.check_constraint_name

from bdd_table t
join bdd_field_table f on f.jid_bdd_table=t.id_bdd_table
join bdc_field_table_list c on c.table_name=t.table_name and c.column_name=f.field_name

