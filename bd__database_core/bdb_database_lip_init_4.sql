-- bdb_database_lip_init_4
-- The database must already exist. Look for 
-- This sql script contains code for the initialization of the postgres lip database with a minimal migration mechanism for the "lip" framework.
-- Run only ONCE after creating the new database.
-- After that we can use the installed migration mechanism to migrate/update the database forward as we develop and deploy.
-- All objects will be created in the schema `lip`
-- run under user `lip_migration_user` on database `lip_01`

create table bdc_source_code
(
    object_name name,
    source_code text not null,
    constraint bdc_source_code_pkey primary key (object_name)
);

create or replace view "bdc_function.list"
as
-- only lip functions
-- select * from "bdc_function.list" ;
select t.routine_name::name as function_name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='lip' and t.routine_type='FUNCTION'
order by function_name;

create view bdc_view_list
as
-- only lip views
-- select * from bdc_view_list ;
select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='lip'
order by t.table_name;

create function bdc_function_drop(i_name name)
returns text
as
-- drop all functions with given i_name regardless of function parameters
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $x$ BEGIN RETURN i + 1; END; $x$ LANGUAGE plpgsql;
-- select bdc_function_drop('test1');   
$function$
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
$function$ language plpgsql;


create function bdc_function_migrate(i_object_name name, i_source_code text)
returns text 
as
-- checks if the function is already installed and if the content of bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdc_source_code only if the installation is successful  
$function$
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdc_source_code a where a.object_name = i_object_name) then
      if exists(select * from "bdc_function.list" p where p.routine_name = i_object_name) then
         select bdc_function_drop(i_object_name) into v_void;
      end if;

      execute i_source_code;

      insert into bdc_source_code (object_name, source_code)
      values (i_object_name, i_source_code);
      return format('Inserted function: %I', i_object_name);
   else
      select a.source_code 
      into v_old_source_code
      from bdc_source_code a
      where a.object_name = i_object_name;

      if i_source_code <> v_old_source_code then
         if exists(select * from "bdc_function.list" p where p.routine_name = i_object_name) then
            select bdc_function_drop(i_object_name) into v_void;
         end if;
         
         execute i_source_code;

         update bdc_source_code
         set source_code = i_source_code
         where object_name = i_object_name;

         return format('Updated function: %I', i_object_name);
      end if;

   end if;
return format('Up to date Function: %I', i_object_name);
end;
$function$ language plpgsql;


create function bdc_view_migrate(i_object_name name, i_source_code text)
returns text 
AS
-- checks if the view is already installed and if the bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new view
-- finally insert/update into bdc_source_code  
$function$
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdc_source_code a where a.object_name = i_object_name) then
      if exists(select * from bdc_view_list v where v.view_name=i_object_name) then
         execute format('DROP VIEW %I CASCADE', i_object_name);
      end if;

      execute i_source_code;

      insert into bdc_source_code (object_name, source_code)
      values (i_object_name, i_source_code);
      return format('Inserted view: %I', i_object_name);
   else
      select a.source_code 
      into v_old_source_code
      from bdc_source_code a
      where a.object_name = i_object_name;

      if i_source_code <> v_old_source_code then
         if exists(select * from bdc_view_list v where v.view_name=i_object_name) then
            execute format('DROP VIEW %I CASCADE', i_object_name);
         end if;
         
         execute i_source_code;

         update bdc_source_code
         set source_code = i_source_code
         where object_name = i_object_name;

         return format('Updated view: %I', i_object_name);
      end if;

   end if;
   return format('Up to date View: %I', i_object_name);
end;
$function$ language plpgsql;
