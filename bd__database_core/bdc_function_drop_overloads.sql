create or replace function "bdc_function_drop_overloads"(i_function_name name)
returns text
as $function$
-- Postgres has this terrible concept of function overloading.
-- I want to have only one function with the same name for sake of my sanity.
-- After `create or replace` I will drop all other overloads.
-- I will leave only the function with the biggest oid number, because that is tha last I installed.
-- My first try was to drop the function before recreating it, 
-- but Postgres does not allow if the function is already been used in a dependent object.
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $x$ BEGIN RETURN i + 1; END; $x$ LANGUAGE plpgsql;
-- select "bdc_function_drop_overloads"('test1');   
declare
    v_sql text;
    v_functions_dropped int;
    v_last_oid int;
begin
    -- the last oib is the last installed function variant and it will remain. 
    -- All older will be dropped.
    select max(p.oid)
    from   pg_catalog.pg_proc p
    where  p.proname = i_function_name
    and p.pronamespace::regnamespace::text='lip'
    into   v_last_oid; 

    select count(*)::int, 'DROP function ' || string_agg(p.oid::regprocedure::text, '; DROP function ')
    from   pg_catalog.pg_proc p
    where  p.proname = i_function_name and p.oid < v_last_oid
    and p.pronamespace::regnamespace::text='lip'
    -- count only returned if subsequent DROPs succeed
    into   v_functions_dropped, v_sql;  

    -- only if function(s) found
    if v_functions_dropped > 0 then
        execute v_sql;
        return v_sql;
    end if;
    return '';

end; $function$ language plpgsql;
