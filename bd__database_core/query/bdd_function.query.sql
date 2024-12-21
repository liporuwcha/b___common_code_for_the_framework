
select "bdd_function.upsert_and_migrate"('bdd_function.upsert_and_migrate',
$sc$

create or replace function "bdd_function.upsert_and_migrate"(i_function_name name, i_source_code text)
returns text
as $function$
-- Update or insert function into bdd_function table. 
declare
    v_id_bdd_function integer;
    v_text text;
    v_text2 text;
begin
    select "bdd_function.upsert"(i_function_name, i_source_code) into v_text;
    select "bdd_function.migrate"(i_function_name) into v_text2;

    return format(E'%s\n%s', v_text, v_text2);
end; $function$ language plpgsql;

$sc$)
