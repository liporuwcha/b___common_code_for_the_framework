select bdc_function_migrate('bdc_function_drop',
$source_code$

create function bdc_function_drop(i_name name)
returns text
as
-- drop all functions with given i_name regardless of function parameters
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $$ BEGIN RETURN i + 1; END; $$ LANGUAGE plpgsql;
-- select bdc_function_drop('test1');   
$$
declare
   v_sql text;
   v_functions_dropped int;
begin
   select count(*)::int
        , 'DROP function ' || string_agg(oid::regprocedure::text, '; DROP function ')
   from   pg_catalog.pg_proc
   where  proname = i_name
   and    pg_function_is_visible(oid)  -- restrict to current search_path
   into   v_functions_dropped, v_sql;     -- count only returned if subsequent DROPs succeed

   if v_functions_dropped > 0 then       -- only if function(s) found
     execute v_sql;
     return v_sql;
   end if;
   return '';
end;
$$ language plpgsql;


$source_code$);
