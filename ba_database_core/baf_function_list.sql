select a2_migrate_view('bdf_function_list',
$source_code$

create view bdf_function_list
as
-- only public functions
-- select * from bdf_function_list ;

select t.routine_name::name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='public' and t.routine_type='FUNCTION'
order by t.routine_name

$source_code$);