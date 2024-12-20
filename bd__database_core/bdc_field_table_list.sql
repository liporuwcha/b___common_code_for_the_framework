select bdc_view_migrate('bdc_field_table_list',
$source_code$

create or replace view bdc_field_table_list
as
-- only lip tables
-- select * from bdc_field_table_list
select
    t.table_name,
    t.column_name,
    t.data_type,
    t.character_maximum_length,
    t.numeric_precision,
    t.is_nullable,
    t.column_default,
    c.check_clause,
    c.constraint_name as check_constraint_name
    
from information_schema.columns t   
left join bdc_constraint_check_single_column_list c on c.table_name=t.table_name and c.column_name=t.column_name
where t.table_schema='lip'
order by t.table_name, t.column_name

$source_code$);
