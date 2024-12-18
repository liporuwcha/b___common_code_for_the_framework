-- This sql script contains code for the initialization of the database with a minimal migration mechanism for the "lip" framework.
-- Run only ONCE after creating the new database.
-- After that we can use the installed migration mechanism to migrate/update the database forward as we develop and deploy.


create table bdf_source_code
(
    object_name name,
    source_code text not null,
    constraint a_source_code_pkey primary key (object_name)
);

create view a1_list_all_functions
as
-- only public functions
-- select * from a1_list_all_functions ;

select t.routine_name::name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='public' and t.routine_type='FUNCTION'
order by t.routine_name;

create view a1_list_all_views
as
-- only public views
-- select * from a1_list_all_views ;

select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='public'
order by t.table_name;

create function a1_drop_function_any_param(_name name)
returns text
as
-- drop all functions with given _name regardless of function parameters
-- test it: create function test1. Then 
-- select a1_drop_function_any_param('test1');   
-- drop function a1_drop_function_any_param;
-- psql -U admin -h localhost -p 5432 -d webpage_hit_counter -f tier3_database_postgres/a1_list_mod/a1_drop_function_any_param.sql_fn
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


create or replace function a2_migrate_function(_object_name name, _source_code text)
returns text 
as
-- checks in the bdf_source_code if the function is already installed
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdf_source_code  
-- psql -U admin -h localhost -p 5432 -d webpage_hit_counter -f tier3_database_postgres/a2_migrate_mod/a2_migrate_function.sql_fn
$$
declare
   _old_source_code text;
   _x_void text;
begin

   if not exists(select * from bdf_source_code a where a.object_name = _object_name) then
      if exists(select * from a1_list_all_functions p where p.routine_name=_object_name) then
         select a1_drop_function_any_param(_object_name) into _x_void;
      end if;

      execute _source_code;

      insert into bdf_source_code (object_name, source_code)
      values (_object_name, _source_code);
      return format('Inserted function: %I', _object_name);
   else
      select a.source_code 
      into _old_source_code
      from bdf_source_code a
      where a.object_name = _object_name;

      if _source_code <> _old_source_code then
         if exists(select * from a1_list_all_functions p where p.routine_name=_object_name) then
            select a1_drop_function_any_param(_object_name) into _x_void;
         end if;
         
         execute _source_code;

         update bdf_source_code
         set source_code = _source_code
         where object_name = _object_name;

         return format('Updated function: %I', _object_name);
      end if;

   end if;
return format('Up to date Function: %I', _object_name);
end;
$$ language plpgsql;


create function a2_migrate_view(_object_name name, _source_code text)
returns text 
AS
-- checks in the bdf_source_code if the view is already installed
-- if is equal, nothing happens
-- else drop the old and install the new view
-- finally insert/update into bdf_source_code  
$$
declare
   _old_source_code text;
   _x_void text;
begin

   if not exists(select * from bdf_source_code a where a.object_name = _object_name) then
      if exists(select * from a1_list_all_views v where v.view_name=_object_name) then
         execute format('DROP VIEW %I CASCADE', _object_name);
      end if;

      execute _source_code;

      insert into bdf_source_code (object_name, source_code)
      values (_object_name, _source_code);
      return format('Inserted view: %I', _object_name);
   else
      select a.source_code 
      into _old_source_code
      from bdf_source_code a
      where a.object_name = _object_name;

      if _source_code <> _old_source_code then
         if exists(select * from a1_list_all_views v where v.view_name=_object_name) then
            execute format('DROP VIEW %I CASCADE', _object_name);
         end if;
         
         execute _source_code;

         update bdf_source_code
         set source_code = _source_code
         where object_name = _object_name;

         return format('Updated view: %I', _object_name);
      end if;

   end if;
   return format('Up to date View: %I', _object_name);
end;
$$ language plpgsql;
