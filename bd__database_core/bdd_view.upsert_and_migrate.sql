create or replace function "bdd_view.upsert_and_migrate"(i_source_code text, i_notes text)
returns text
as $function$
-- Update or insert view into bdd_view table. 
-- select "bdd_view.upsert_and_migrate"('create or replace view "aa123.456_789"() returns text as $x$ begin end;$x$ language plpgsql;');
declare
    v_id_bdd_view integer;
    v_text text;
    v_text2 text;
    v_temp_source_code text;
    v_pos_first integer;
    v_pos_second integer;
    v_prefix text='create or replace view "';
    v_view_name name;
    is_valid_name boolean;
begin
    -- parse the source code to extract the view name
    -- the source code must always start with 
    -- [create or replace view "view_name"]
    -- the double quote delimiters are mandatory

    select bdc_trim_whitespace(i_source_code) into v_temp_source_code;
    if not starts_with(v_temp_source_code,v_prefix) then
        raise exception 'Error: view_name cannot be parsed and extracted from source_code! The view code must start with [create or replace view "]. The double quotes are mandatory.';
    end if;

    -- find the second double quote to extract the view_name
    select length(v_prefix)+1 into v_pos_first;
    select position('"' in substring(v_temp_source_code, v_pos_first ,1000))-1+v_pos_first into v_pos_second;
    select substring(v_temp_source_code,v_pos_first,v_pos_second-v_pos_first) into v_view_name;
    raise notice 'view_name: %', v_view_name;
    -- regex check: view names can have only lowercase letters, numerics, _ and dot.
    SELECT v_view_name ~ '^[a-z0-9_\.]*$' into is_valid_name;
    if is_valid_name = false then
        raise exception 'Error: Only lowercase letters, numerics, underscore and dot are allowed for view_name: %', v_view_name;        raise exception 'regex is ok';  
    end if;

    select "bdd_view.upsert"(v_view_name, v_temp_source_code, i_notes) into v_text;
    select "bdd_view.migrate"(v_view_name) into v_text2;

    return format(E'%s\n%s', v_text2, v_text);
end; $function$ language plpgsql;
