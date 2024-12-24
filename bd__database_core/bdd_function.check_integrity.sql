-- check if all the functions in bdd_function are installed into the database
-- check if all installed functions have their definition in bdd_function

select * 
from "bdc_function.list" c
left join "bdd_function" d on d.function_name=c.function_name
where d.function_name is null;

select *
from "bdd_function" d
left join "bdc_function.list" c on c.function_name=d.function_name
where c.function_name is null
