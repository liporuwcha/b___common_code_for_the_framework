-- bdc_database_lip_init_4
-- The database must already exist. Look for 
-- This sql script contains code for the initialization of the postgres lip database with a minimal migration mechanism for the "lip" framework.
-- Run only ONCE after creating the new database.
-- After that we can use the installed migration mechanism to migrate/update the database forward as we develop and deploy.
-- All objects will be created in the schema `lip_schema`
-- run under user `lip_migration_user` on database `lip_01`

create table bdo_source_code
(
    object_name name,
    source_code text not null,
    constraint a_source_code_pkey primary key (object_name)
);

create view bdo_function_list
as
-- only public functions
-- select * from bdo_function_list ;

select t.routine_name::name, 
t.specific_name::name, 
t.type_udt_name::name
from information_schema.routines t
where t.routine_schema='public' and t.routine_type='FUNCTION'
order by t.routine_name;

create view bdo_view_list
as
-- only public views
-- select * from bdo_view_list ;

select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='public'
order by t.table_name;

create function bdo_function_drop(i_name name)
returns text
as
-- drop all functions with given i_name regardless of function parameters
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $$ BEGIN RETURN i + 1; END; $$ LANGUAGE plpgsql;
-- select bdo_function_drop('test1');   
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


create function bdo_function_migrate(i_object_name name, i_source_code text)
returns text 
as
-- checks if the function is already installed and if the content of bdo_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdo_source_code only if the installation is successful  
$$
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdo_source_code a where a.object_name = i_object_name) then
      if exists(select * from bdo_function_list p where p.routine_name = i_object_name) then
         select bdo_function_drop(i_object_name) into v_void;
      end if;

      execute i_source_code;

      insert into bdo_source_code (object_name, source_code)
      values (i_object_name, i_source_code);
      return format('Inserted function: %I', i_object_name);
   else
      select a.source_code 
      into v_old_source_code
      from bdo_source_code a
      where a.object_name = i_object_name;

      if i_source_code <> v_old_source_code then
         if exists(select * from bdo_function_list p where p.routine_name = i_object_name) then
            select bdo_function_drop(i_object_name) into v_void;
         end if;
         
         execute i_source_code;

         update bdo_source_code
         set source_code = i_source_code
         where object_name = i_object_name;

         return format('Updated function: %I', i_object_name);
      end if;

   end if;
return format('Up to date Function: %I', i_object_name);
end;
$$ language plpgsql;


create function bdo_view_migrate(i_object_name name, i_source_code text)
returns text 
AS
-- checks if the view is already installed and if the bdo_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new view
-- finally insert/update into bdo_source_code  
$$
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdo_source_code a where a.object_name = i_object_name) then
      if exists(select * from bdo_view_list v where v.view_name=i_object_name) then
         execute format('DROP VIEW %I CASCADE', i_object_name);
      end if;

      execute i_source_code;

      insert into bdo_source_code (object_name, source_code)
      values (i_object_name, i_source_code);
      return format('Inserted view: %I', i_object_name);
   else
      select a.source_code 
      into v_old_source_code
      from bdo_source_code a
      where a.object_name = i_object_name;

      if i_source_code <> v_old_source_code then
         if exists(select * from bdo_view_list v where v.view_name=i_object_name) then
            execute format('DROP VIEW %I CASCADE', i_object_name);
         end if;
         
         execute i_source_code;

         update bdo_source_code
         set source_code = i_source_code
         where object_name = i_object_name;

         return format('Updated view: %I', i_object_name);
      end if;

   end if;
   return format('Up to date View: %I', i_object_name);
end;
$$ language plpgsql;