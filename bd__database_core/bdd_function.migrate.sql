select "bdd_function.upsert_and_migrate"('bdd_function.migrate',
$source_code$

create or replace function "bdd_function.migrate"(i_function_name name)
returns text 
as $function$
-- install the function from bdd into postgres
-- if the function is modified
-- select "bdd_function.migrate"('bdc_function_drop')
declare
    v_source_code text;
    v_text text;
begin

select f.source_code into v_source_code from bdd_function f where f.function_name=i_function_name;

select bdc_function_migrate into v_text from bdc_function_migrate(i_function_name, v_source_code);

return v_text;
end; $function$ language plpgsql;

$source_code$);
