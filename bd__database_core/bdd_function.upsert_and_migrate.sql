create or replace function "bdd_function.upsert_and_migrate"(i_source_code text)
returns text
as $function$
-- Update or insert function into bdd_function table. 
-- select "bdd_function.upsert_and_migrate"('create or replace function "aa123.456_789"() returns text as $x$ begin end;$x$ language plpgsql;');
declare
    v_id_bdd_function integer;
    v_text text;
    v_text2 text;
    v_temp_source_code text;
    v_pos_first integer;
    v_pos_second integer;
    v_prefix text='create or replace function "';
    v_function_name name;
    is_valid_name boolean;
begin
    -- parse the source code to extract the function name
    -- the source code must always start with 
    -- [create or replace function "function_name"]
    -- the double quote delimiters are mandatory

    select bdc_trim_whitespace(i_source_code) into v_temp_source_code;
    if not starts_with(v_temp_source_code,v_prefix) then
        raise exception 'Error: function_name cannot be parsed and extracted from source_code! The function code must start with [create or replace function "]. The double quotes are mandatory.';
    end if;

    -- find the second double quote to extract the function_name
    select length(v_prefix)+1 into v_pos_first;
    select position('"' in substring(v_temp_source_code, v_pos_first ,1000))-1+v_pos_first into v_pos_second;
    select substring(v_temp_source_code,v_pos_first,v_pos_second-v_pos_first) into v_function_name;
    raise notice 'function_name: %', v_function_name;
    -- regex check: function names can have only lowercase letters, numerics, _ and dot.
    SELECT v_function_name ~ '^[a-z0-9_\.]*$' into is_valid_name;
    if is_valid_name = false then
        raise exception 'Error: Only lowercase letters, numerics, underscore and dot are allowed for function_name: %', v_function_name;        raise exception 'regex is ok';  
    end if;

    select "bdd_function.upsert"(v_function_name, i_source_code) into v_text;
    select "bdd_function.migrate"(v_function_name) into v_text2;

    return format(E'%s\n%s', v_text2, v_text);
end; $function$ language plpgsql;
