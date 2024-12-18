-- tier3_database_postgres/a1_list_mod/bdf_function_drop.sql_fn

-- select bdf_function_drop('bdf_function_drop');

select bdf_function_create_or_replace('bdf_function_drop',
$source_code$

create function bdf_function_drop(_name name)
returns text
as
-- drop all functions with given _name regardless of function parameters
-- test it: create function test1. Then 
-- select bdf_function_drop('test1');   
-- drop function bdf_function_drop;
-- psql -U admin -h localhost -p 5432 -d webpage_hit_counter -f tier3_database_postgres/a1_list_mod/bdf_function_drop.sql_fn
$$
declare
   _sql text;
   _functions_dropped int;
begin
   select count(*)::int
        , 'DROP function ' || string_agg(oid::regprocedure::text, '; DROP function ')
   from   pg_catalog.pg_proc
   where  proname = _name
   and    pg_function_is_visible(oid)  -- restrict to current search_path
   into   _functions_dropped, _sql;     -- count only returned if subsequent DROPs succeed

   if _functions_dropped > 0 then       -- only if function(s) found
     execute _sql;
     return _sql;
   end if;
   return '';
end;
$$ language plpgsql;

$source_code$);
