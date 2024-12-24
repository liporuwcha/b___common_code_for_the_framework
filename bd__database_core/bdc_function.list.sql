create or replace view "bdc_function.list"
as
-- only lip functions
select t.routine_name::name as function_name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='lip' and t.routine_type='FUNCTION'
order by function_name
