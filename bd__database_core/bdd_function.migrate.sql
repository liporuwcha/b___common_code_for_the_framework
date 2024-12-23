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

select f.source_code from bdd_function f where f.function_name=i_function_name into v_source_code;

select bdc_function_migrate from bdc_function_migrate(i_function_name, v_source_code) into v_text;

return v_text;
end; $function$ language plpgsql;
