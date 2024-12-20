select bdc_view_migrate('bdc_function_list',
$source_code$

create or replace view bdc_function_list
as
-- only lip functions
select t.routine_name::name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='lip' and t.routine_type='FUNCTION'
order by t.routine_name

$source_code$);
