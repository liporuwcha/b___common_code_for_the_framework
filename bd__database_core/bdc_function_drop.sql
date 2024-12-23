create or replace function bdc_function_drop(i_name name)
returns text
as $function$
-- drop all function overloads with given i_name regardless of function parameters
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $x$ BEGIN RETURN i + 1; END; $x$ LANGUAGE plpgsql;
-- select bdc_function_drop('test1');   
declare
   v_sql text;
   v_functions_dropped int;
begin
   select count(*)::int
        , 'DROP function ' || string_agg(p.oid::regprocedure::text, '; DROP function ')
   from   pg_catalog.pg_proc p
   where  p.proname = i_name
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
