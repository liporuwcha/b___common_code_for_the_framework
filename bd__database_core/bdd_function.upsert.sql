create or replace function "bdd_function.upsert"(i_function_name name, i_source_code text)
returns text
as $function$
-- Update or insert function into bdd_function table. 
declare
    v_id_bdd_function integer;
    v_text text;
begin

    if not starts_with(bdc_trim_whitespace(i_source_code), format('create or replace function "%I"', i_function_name)) then
        return format('Error: %s function name is not right.', i_function_name);
    end if;

    select p.id_bdd_function
    from   bdd_function p
    where  p.function_name = i_function_name
    into v_id_bdd_function;

    if v_id_bdd_function is null THEN

        insert into bdd_function ( id_bdd_function, source_code, function_name )
        values ( bdc_random_int(), bdc_trim_whitespace(i_source_code), i_function_name );

        return format('Function inserted %s',i_function_name);
    else

        update bdd_function t set source_code = bdc_trim_whitespace(i_source_code)
        where t.function_name = i_function_name;
        
        return format('Function updated %s',i_function_name);
    end if;
end; $function$ language plpgsql;
