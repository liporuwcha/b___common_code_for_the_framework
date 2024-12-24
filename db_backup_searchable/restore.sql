--
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 15.7 (Debian 15.7-1.pgdg120+1)
-- Dumped by pg_dump version 15.10 (Debian 15.10-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE lip_01;
--
-- Name: lip_01; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE lip_01 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE lip_01 OWNER TO postgres;

\connect lip_01

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: lip_01; Type: DATABASE PROPERTIES; Schema: -; Owner: postgres
--

ALTER DATABASE lip_01 SET search_path TO 'lip_schema';


\connect lip_01

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: lip; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA lip;


ALTER SCHEMA lip OWNER TO postgres;

--
-- Name: dm_description; Type: DOMAIN; Schema: lip; Owner: lip_migration_user
--

CREATE DOMAIN lip.dm_description AS text NOT NULL DEFAULT ''::text;


ALTER DOMAIN lip.dm_description OWNER TO lip_migration_user;

--
-- Name: dm_positive_integer; Type: DOMAIN; Schema: lip; Owner: lip_migration_user
--

CREATE DOMAIN lip.dm_positive_integer AS integer
	CONSTRAINT dm_positive_integer_check CHECK ((VALUE > 0));


ALTER DOMAIN lip.dm_positive_integer OWNER TO lip_migration_user;

--
-- Name: dm_system_name; Type: DOMAIN; Schema: lip; Owner: lip_migration_user
--

CREATE DOMAIN lip.dm_system_name AS character varying(100) NOT NULL
	CONSTRAINT dm_system_name_check CHECK ((length((VALUE)::text) > 0));


ALTER DOMAIN lip.dm_system_name OWNER TO lip_migration_user;

--
-- Name: bdc_function_drop(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_function_drop(i_name name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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

end; $_$;


ALTER FUNCTION lip.bdc_function_drop(i_name name) OWNER TO postgres;

--
-- Name: bdc_function_drop_overloads(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_function_drop_overloads(i_function_name name) RETURNS text
    LANGUAGE plpgsql
    AS $_$
-- Postgres has this terrible concept of function overloading.
-- I want to have only one function with the same name for sake of my sanity.
-- After `create or replace` I will drop all other overloads.
-- I will leave only the function with the biggest oid number, because that is tha last I installed.
-- My first try was to drop the function before recreating it, 
-- but Postgres does not allow if the function is already been used in a dependent object.
-- test it, create the function test1() and then drop it: 
-- CREATE FUNCTION test1(i integer) RETURNS integer AS $x$ BEGIN RETURN i + 1; END; $x$ LANGUAGE plpgsql;
-- select bdc_function_drop_overloads('test1');   
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

end; $_$;


ALTER FUNCTION lip.bdc_function_drop_overloads(i_function_name name) OWNER TO postgres;

--
-- Name: bdc_function_migrate(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_function_migrate(i_function_name name, i_source_code text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- checks if the function is already installed and if the content of bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdc_source_code only if the installation is successful  
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdc_source_code a where a.object_name = i_function_name) then
      if exists(select * from bdc_function_list p where p.routine_name = i_function_name) then
         -- must not drop functions because of the error: 
         -- cannot drop function because other objects depend on it.
         select bdc_function_drop(i_function_name) into v_void;
      end if;

      execute i_source_code;

      insert into bdc_source_code (object_name, source_code)
      values (i_function_name, i_source_code);

      select bdc_function_drop_overloads(i_function_name) into v_void;

      return format('Inserted function: %I', i_function_name);
   else
      select a.source_code 
      from bdc_source_code a
      where a.object_name = i_function_name
      into v_old_source_code;

      if i_source_code <> v_old_source_code then
         
         execute i_source_code;

         update bdc_source_code s
         set source_code = i_source_code
         where s.object_name = i_function_name;

         select bdc_function_drop_overloads(i_function_name) into v_void;

         return format('Updated function: %I', i_function_name);
      else
         return format('Function is up to date: %I', i_function_name);
      end if;

   end if;

end; $$;


ALTER FUNCTION lip.bdc_function_migrate(i_function_name name, i_source_code text) OWNER TO postgres;

--
-- Name: bdc_random_int(); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_random_int() RETURNS integer
    LANGUAGE sql
    AS $$
    select FLOOR(RANDOM()*2147483646::double precision) + 1;
$$;


ALTER FUNCTION lip.bdc_random_int() OWNER TO postgres;

--
-- Name: bdc_strip_prefix(text, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_strip_prefix(i_string text, i_prefix text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- Returns a string with the prefix removed
-- select bdc_strip_prefix('123456789','123')
-- select bdc_strip_prefix('123456789','1')
-- select bdc_strip_prefix('123456789','') - returns the same string
-- select bdc_strip_prefix('123456789','999') - returns the same string
-- select bdc_strip_prefix('123456789','123456789') - returns empty string
-- select bdc_strip_prefix('12345','123456789') - returns the same string
-- select bdc_strip_prefix('123456789',null) - returns the same string
-- select bdc_strip_prefix(null,'123') - returns null
begin
if starts_with(i_string, i_prefix) then
    return substring(i_string, length(i_prefix)+1);
else
    return i_string;
end if;

end; $$;


ALTER FUNCTION lip.bdc_strip_prefix(i_string text, i_prefix text) OWNER TO postgres;

--
-- Name: bdc_trim_whitespace(text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_trim_whitespace(i_string text) RETURNS text
    LANGUAGE sql
    AS $$
    SELECT trim(i_string,E' \n\r\t'); 
$$;


ALTER FUNCTION lip.bdc_trim_whitespace(i_string text) OWNER TO postgres;

--
-- Name: bdc_view_migrate(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip.bdc_view_migrate(i_object_name name, i_source_code text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- checks if the view is already installed and if the bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new view
-- finally insert/update into bdc_source_code  
declare
   v_old_source_code text;
   v_sql text;
begin

   if not exists(select * from bdc_source_code a where a.object_name = i_object_name) then
      if exists(select * from bdc_view_list v where v.view_name=i_object_name) then
         v_sql = format('drop view %i cascade', i_object_name);
         RAISE '%s', v_sql;
         execute v_sql;
      end if;

      execute i_source_code;

      insert into bdc_source_code (object_name, source_code)
      values (i_object_name, i_source_code);

      return format('Inserted view: %I', i_object_name);
   else
      select a.source_code 
      from bdc_source_code a
      where a.object_name = i_object_name
      into v_old_source_code;

      if i_source_code <> v_old_source_code then
         if exists(select * from bdc_view_list v where v.view_name=i_object_name) then
            execute format('DROP VIEW %I CASCADE', i_object_name);
         end if;
      else
         return format('View is up to date: %I', i_object_name);
      end if;

      if not exists(select * from bdc_view_list v where v.view_name=i_object_name) then
         execute i_source_code;

         update bdc_source_code s
         set source_code = i_source_code
         where s.object_name = i_object_name;

         return format('Updated view: %I', i_object_name);
      end if;
   end if;

end; $$;


ALTER FUNCTION lip.bdc_view_migrate(i_object_name name, i_source_code text) OWNER TO postgres;

--
-- Name: bdd_function.migrate(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_function.migrate"(i_function_name name) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- install the function from bdd into postgres
-- if the function is modified
-- select "bdd_function.migrate"('bdc_function_drop')
declare
    v_source_code text;
    v_text text;
begin

select f.source_code from bdd_function f where f.function_name=i_function_name into v_source_code;

select bdc_function_migrate from bdc_function_migrate(i_function_name, v_source_code) into v_text;

return v_text;
end; $$;


ALTER FUNCTION lip."bdd_function.migrate"(i_function_name name) OWNER TO postgres;

--
-- Name: bdd_function.upsert(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_function.upsert"(i_function_name name, i_source_code text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- Update or insert function into bdd_function table. 
declare
    v_id_bdd_function integer;
    v_text text;
begin

    if not starts_with(bdc_trim_whitespace(i_source_code), format('create or replace function %I', i_function_name)) then
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
end; $$;


ALTER FUNCTION lip."bdd_function.upsert"(i_function_name name, i_source_code text) OWNER TO postgres;

--
-- Name: bdd_function.upsert_and_migrate(text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_function.upsert_and_migrate"(i_source_code text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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

    select "bdd_function.upsert"(v_function_name, v_temp_source_code) into v_text;
    select "bdd_function.migrate"(v_function_name) into v_text2;

    return format(E'%s\n%s', v_text2, v_text);
end; $_$;


ALTER FUNCTION lip."bdd_function.upsert_and_migrate"(i_source_code text) OWNER TO postgres;

--
-- Name: bdd_table.insert(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_table.insert"(i_table_name name, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- insert into bdd_table table.
-- select "bdd_table.insert"('bdd_view2','')
declare
    v_id_bdd_table integer;
    v_text text;
    v_record record;
begin
    insert into bdd_table ( id_bdd_table, table_name, notes )
    values ( bdc_random_int(), i_table_name, i_notes )
    returning *
    into v_record;

    return format('Table inserted %s %s',v_record.id_bdd_table, i_table_name);

end; $$;


ALTER FUNCTION lip."bdd_table.insert"(i_table_name name, i_notes text) OWNER TO postgres;

--
-- Name: bdd_table.migrate(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_table.migrate"(i_table_name name) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- checks if the table has all the fields
-- if needed it adds the fields 
-- select * from "bdd_table.migrate"('bdd_view')
declare
    v_row record;
    v_sql text;
    v_sql_fields text;
    v_void text;
    v_id_bdd_table integer;
begin
    -- set the variable for id_bdd_table
    -- the expression will set the variables to NULL if no rows were returned
    select t.id_bdd_table from bdd_table t where t.table_name = i_table_name into v_id_bdd_table;
    if v_id_bdd_table is null then
        -- early return
        return format('Error: Definition for %s is not in bdd_table.', i_table_name);
    end if;

    RAISE NOTICE 'Found definition for %s in bdd_table', i_table_name;

    if not exists(select * from bdc_table_list a where a.table_name=i_table_name) then
        -- if table not exists, create it with all fields in one go.
        -- prepare code for fields
        FOR v_row IN
            select f.field_name, f.data_type, f.not_null, f.default_constraint, f.check_constraint
            from bdd_field_table f
            where f.jid_bdd_table = v_id_bdd_table
        LOOP
            if v_sql_fields != '' then
                v_sql_fields = format(E'%s ,\n', v_sql_fields);
            end if;
            v_sql_fields = format('%s %s %s %s %s %s', v_sql_fields, v_row.field_name, v_row.data_type, v_row.not_null, v_row.default_constraint, v_row.check_constraint);
            raise notice '%', v_sql_fields;
        END LOOP;

        v_sql = format(E'create table %s (\n%s\n)', i_table_name, v_sql_fields);
        execute v_sql;

        return format(E'executed sql code:\n%s', v_sql);
    else
        -- table exists, what fields don't exist?
        -- prepare code for missing fields
        FOR v_row IN
            select f.field_name, f.data_type, f.not_null, f.default_constraint, f.check_constraint
            from bdd_field_table f
            where f.jid_bdd_table = v_id_bdd_table
            and not exists(select * from bdc_field_table_list c where c.table_name=i_table_name and c.column_name=f.field_name)
            
        LOOP
            if v_sql_fields != '' then
                v_sql_fields = format(E'%s ,\n', v_sql_fields);
            end if;
            v_sql_fields = format('add column %s %s %s %s %s %s', v_sql_fields, v_row.field_name, v_row.data_type, v_row.not_null, v_row.default_constraint, v_row.check_constraint);

        END LOOP;

        v_sql = format(E'alter table %s \n%s\n;', i_table_name, v_sql_fields);
        execute v_sql;
        return format(E'executed sql code:\n%s', v_sql);
    end if;

end; $$;


ALTER FUNCTION lip."bdd_table.migrate"(i_table_name name) OWNER TO postgres;

--
-- Name: bdd_table.migrate_details(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_table.migrate_details"(i_table_name name) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- checks if the the table fields have the same details in the database as in the definition: 
-- data_type, not_null, check_constraint, default_constraint
-- select * from "bdd_table.migrate_details"('test1')
declare
    v_row record;
    v_sql text;
    v_sql_field text;
    v_void text;
    v_id_bdd_table integer;
begin
    -- set the variable for id_bdd_table
    -- the expression will set the variables to NULL if no rows were returned
    select t.id_bdd_table from bdd_table t where t.table_name = i_table_name into v_id_bdd_table;
    if v_id_bdd_table is null then
        -- early return
        return format('Error: Definition for %s is not in bdd_table.', i_table_name);
    end if;

    FOR v_row IN
        select f.table_name, f.field_name, f.data_type
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.data_type_formatted != f.bdc_data_type_formatted
    LOOP
        v_sql_field = format(E'alter table %I alter column %I type %s;',i_table_name, v_row.field_name, v_row.data_type);
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.not_null
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.not_null_formatted != f.bdc_is_nullable_formatted
    LOOP
        if v_row.not_null = '' THEN
            v_sql_field = format(E'alter table %I alter column %I drop not null;',i_table_name, v_row.field_name);
        ELSE
            v_sql_field = format(E'alter table %I alter column %I set not null;',i_table_name, v_row.field_name);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.default_constraint
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.default_constraint_formatted != f.bdc_column_default_formatted
    LOOP
        if v_row.default_constraint = '' then
            v_sql_field = format(E'alter table %I alter column %I drop default;',i_table_name, v_row.field_name);
        else
            v_sql_field = format(E'alter table %I alter column %I set %s;',i_table_name, v_row.field_name, v_row.default_constraint);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.check_constraint, f.check_constraint_name
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.check_constraint_formatted != f.bdc_check_clause_formatted
    LOOP
        if v_row.check_constraint = '' then
            v_sql_field = format(E'alter table %I alter column %I drop constraint %s;',i_table_name, v_row.field_name, v_row.check_constraint_name);
        else
            v_sql_field = format(E'alter table %I add %s;',i_table_name, v_row.check_constraint);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;
    return format(E'executed sql code:\n%s', v_sql);

end; $$;


ALTER FUNCTION lip."bdd_table.migrate_details"(i_table_name name) OWNER TO postgres;

--
-- Name: bdd_table.update(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_table.update"(i_table_name name, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- update into bdd_table table.
-- select "bdd_table.update"('bdd_view','')
declare
    v_record record;
begin
    update bdd_table 
    set notes=i_notes
    where table_name=i_table_name
    returning *
    into v_record;

    return format('Table updated %s %s',v_record.id_bdd_table, i_table_name);

end; $$;


ALTER FUNCTION lip."bdd_table.update"(i_table_name name, i_notes text) OWNER TO postgres;

--
-- Name: bdd_table.upsert(name, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_table.upsert"(i_table_name name, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- Update or insert function into bdd_table table.
-- select "bdd_table.upsert"('bdd_view','')
declare
    v_id_bdd_table integer;
    v_text text;
begin

    select p.id_bdd_table
    from   bdd_table p
    where  p.table_name = i_table_name
    into v_id_bdd_table;

    if v_id_bdd_table is null THEN
        select "bdd_table.insert"(i_table_name, i_notes) into v_text;
        return format('%s',v_text);
    else
        select "bdd_table.update"(i_table_name, i_notes) into v_text;
        return format('%s',v_text);
    end if;
end; $$;


ALTER FUNCTION lip."bdd_table.upsert"(i_table_name name, i_notes text) OWNER TO postgres;

--
-- Name: bdd_view.insert(name, text, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_view.insert"(i_view_name name, i_source_code text, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- insert into bdd_view table.
-- select "bdd_view.insert"('bdd_view2','','')
declare
    v_id_bdd_view integer;
    v_text text;
    v_record record;
begin
    insert into bdd_view ( id_bdd_view, view_name, source_code, notes )
    values ( bdc_random_int(), i_view_name, i_source_code, i_notes )
    returning *
    into v_record;

    return format('Table inserted %s %s',v_record.id_bdd_view, i_view_name);

end; $$;


ALTER FUNCTION lip."bdd_view.insert"(i_view_name name, i_source_code text, i_notes text) OWNER TO postgres;

--
-- Name: bdd_view.migrate(name); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_view.migrate"(i_view_name name) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- install the view from bdd into postgres
-- if the view is modified
-- select "bdd_view.migrate"('bdc_view_drop')
declare
    v_source_code text;
    v_text text;
begin

select f.source_code from bdd_view f where f.view_name=i_view_name into v_source_code;

select bdc_view_migrate from bdc_view_migrate(i_view_name, v_source_code) into v_text;

return v_text;
end; $$;


ALTER FUNCTION lip."bdd_view.migrate"(i_view_name name) OWNER TO postgres;

--
-- Name: bdd_view.update(name, text, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_view.update"(i_view_name name, i_source_code text, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- update bdd_view table.
-- select "bdd_view.update"('bdd_view','')
declare
    v_record record;
begin
    update bdd_view 
    set source_code=i_source_code, notes=i_notes
    where view_name=i_view_name
    returning *
    into v_record;

    return format('Table updated %s %s',v_record.id_bdd_view, i_view_name);

end; $$;


ALTER FUNCTION lip."bdd_view.update"(i_view_name name, i_source_code text, i_notes text) OWNER TO postgres;

--
-- Name: bdd_view.upsert(name, text, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_view.upsert"(i_view_name name, i_source_code text, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $$
-- Update or insert function into bdd_view table.
-- select "bdd_view.upsert"('bdd_view','')
declare
    v_id_bdd_view integer;
    v_text text;
begin

    select p.id_bdd_view
    from   bdd_view p
    where  p.view_name = i_view_name
    into v_id_bdd_view;

    if v_id_bdd_view is null THEN
        select "bdd_view.insert"(i_view_name, i_source_code, i_notes) into v_text;
        return format('%s',v_text);
    else
        select "bdd_view.update"(i_view_name, i_source_code, i_notes) into v_text;
        return format('%s',v_text);
    end if;
end; $$;


ALTER FUNCTION lip."bdd_view.upsert"(i_view_name name, i_source_code text, i_notes text) OWNER TO postgres;

--
-- Name: bdd_view.upsert_and_migrate(text, text); Type: FUNCTION; Schema: lip; Owner: postgres
--

CREATE FUNCTION lip."bdd_view.upsert_and_migrate"(i_source_code text, i_notes text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
end; $_$;


ALTER FUNCTION lip."bdd_view.upsert_and_migrate"(i_source_code text, i_notes text) OWNER TO postgres;

--
-- Name: bdc_constraint_check_single_column_list; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip.bdc_constraint_check_single_column_list AS
 SELECT tc.table_name,
    tc.constraint_name,
    col.column_name,
    cc.check_clause
   FROM (((information_schema.table_constraints tc
     JOIN information_schema.check_constraints cc ON (((cc.constraint_name)::name = (tc.constraint_name)::name)))
     JOIN pg_constraint pgc ON (((pgc.conname = (cc.constraint_name)::name) AND (pgc.contype = 'c'::"char") AND (array_length(pgc.conkey, 1) = 1))))
     JOIN information_schema.columns col ON ((((col.table_schema)::name = (tc.table_schema)::name) AND ((col.table_name)::name = (tc.table_name)::name) AND ((col.ordinal_position)::integer = ANY (pgc.conkey)))))
  WHERE (((tc.table_schema)::name = 'lip'::name) AND ((tc.constraint_type)::text = 'CHECK'::text));


ALTER TABLE lip.bdc_constraint_check_single_column_list OWNER TO postgres;

--
-- Name: bdc_field_table_list; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip.bdc_field_table_list AS
 SELECT t.table_name,
    t.column_name,
    t.data_type,
    t.character_maximum_length,
    t.numeric_precision,
    t.is_nullable,
    t.column_default,
    c.check_clause,
    c.constraint_name AS check_constraint_name
   FROM (information_schema.columns t
     LEFT JOIN lip.bdc_constraint_check_single_column_list c ON ((((c.table_name)::name = (t.table_name)::name) AND ((c.column_name)::name = (t.column_name)::name))))
  WHERE ((t.table_schema)::name = 'lip'::name)
  ORDER BY t.table_name, t.column_name;


ALTER TABLE lip.bdc_field_table_list OWNER TO postgres;

--
-- Name: bdc_function.list; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip."bdc_function.list" AS
 SELECT (t.routine_name)::name AS function_name,
    (t.specific_name)::name AS specific_name,
    (t.type_udt_name)::name AS type_udt_name
   FROM information_schema.routines t
  WHERE (((t.routine_schema)::name = 'lip'::name) AND ((t.routine_type)::text = 'FUNCTION'::text))
  ORDER BY (t.routine_name)::name;


ALTER TABLE lip."bdc_function.list" OWNER TO postgres;

--
-- Name: bdc_function_list; Type: VIEW; Schema: lip; Owner: lip_migration_user
--

CREATE VIEW lip.bdc_function_list AS
 SELECT (t.routine_name)::name AS routine_name,
    (t.specific_name)::name AS specific_name,
    (t.type_udt_name)::name AS type_udt_name
   FROM information_schema.routines t
  WHERE (((t.routine_schema)::name = 'lip'::name) AND ((t.routine_type)::text = 'FUNCTION'::text))
  ORDER BY t.routine_name;


ALTER TABLE lip.bdc_function_list OWNER TO lip_migration_user;

--
-- Name: bdc_role_list; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip.bdc_role_list AS
 SELECT pg_user.usename AS role_name,
        CASE
            WHEN (pg_user.usesuper AND pg_user.usecreatedb) THEN 'superuser, create database'::text
            WHEN pg_user.usesuper THEN 'superuser'::text
            WHEN pg_user.usecreatedb THEN 'create database'::text
            ELSE ''::text
        END AS role_attributes
   FROM pg_user
  ORDER BY pg_user.usename DESC;


ALTER TABLE lip.bdc_role_list OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bdc_source_code; Type: TABLE; Schema: lip; Owner: lip_migration_user
--

CREATE TABLE lip.bdc_source_code (
    object_name name NOT NULL,
    source_code text NOT NULL,
    CONSTRAINT bdc_source_code_object_name_check CHECK ((length((object_name)::text) > 0))
);


ALTER TABLE lip.bdc_source_code OWNER TO lip_migration_user;

--
-- Name: bdc_table_list; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip.bdc_table_list AS
 SELECT t.table_name
   FROM information_schema.tables t
  WHERE (((t.table_schema)::name = 'lip'::name) AND ((t.table_type)::text = 'BASE TABLE'::text));


ALTER TABLE lip.bdc_table_list OWNER TO postgres;

--
-- Name: bdc_view_list; Type: VIEW; Schema: lip; Owner: lip_migration_user
--

CREATE VIEW lip.bdc_view_list AS
 SELECT (t.table_name)::name AS view_name
   FROM information_schema.views t
  WHERE ((t.table_schema)::name = 'lip'::name)
  ORDER BY t.table_name;


ALTER TABLE lip.bdc_view_list OWNER TO lip_migration_user;

--
-- Name: bdd_domain; Type: TABLE; Schema: lip; Owner: lip_migration_user
--

CREATE TABLE lip.bdd_domain (
    id_bdd_domain integer NOT NULL,
    domain_name name NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    source_code text NOT NULL,
    CONSTRAINT bdd_domain_id_bdd_domain_check CHECK ((id_bdd_domain > 0)),
    CONSTRAINT bdd_domain_name_domain_check CHECK ((length((domain_name)::text) > 2))
);


ALTER TABLE lip.bdd_domain OWNER TO lip_migration_user;

--
-- Name: bdd_field_table; Type: TABLE; Schema: lip; Owner: lip_migration_user
--

CREATE TABLE lip.bdd_field_table (
    id_bdd_field_table integer NOT NULL,
    jid_bdd_table integer NOT NULL,
    field_name name NOT NULL,
    data_type character varying(100) NOT NULL,
    not_null character varying(10) DEFAULT ''::character varying NOT NULL,
    default_constraint character varying(100) DEFAULT ''::character varying,
    check_constraint character varying(100) DEFAULT ''::character varying,
    CONSTRAINT bdd_field_table_data_type_check CHECK ((length((data_type)::text) > 0)),
    CONSTRAINT bdd_field_table_field_name_check CHECK ((length((field_name)::text) > 0))
);


ALTER TABLE lip.bdd_field_table OWNER TO lip_migration_user;

--
-- Name: bdd_table; Type: TABLE; Schema: lip; Owner: lip_migration_user
--

CREATE TABLE lip.bdd_table (
    id_bdd_table integer NOT NULL,
    table_name name DEFAULT ''::name NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    CONSTRAINT bdd_table_table_name_check CHECK ((length((table_name)::text) > 2))
);


ALTER TABLE lip.bdd_table OWNER TO lip_migration_user;

--
-- Name: bdd_field_table.details; Type: VIEW; Schema: lip; Owner: postgres
--

CREATE VIEW lip."bdd_field_table.details" AS
 SELECT t.table_name,
    f.field_name,
    f.data_type,
    f.data_type AS data_type_formatted,
        CASE
            WHEN ((c.data_type)::text = 'character varying'::text) THEN (format('varchar(%s)'::text, c.character_maximum_length))::character varying
            ELSE (c.data_type)::character varying
        END AS bdc_data_type_formatted,
    f.not_null,
    f.not_null AS not_null_formatted,
        CASE
            WHEN ((c.is_nullable)::text = 'YES'::text) THEN ''::text
            ELSE 'not null'::text
        END AS bdc_is_nullable_formatted,
    f.default_constraint,
        CASE
            WHEN ((f.default_constraint)::text = ''::text) THEN ''::text
            ELSE format('%s'::text, lip.bdc_strip_prefix((f.default_constraint)::text, 'default '::text))
        END AS default_constraint_formatted,
    replace(replace((COALESCE((c.column_default)::character varying, ''::character varying))::text, '::character varying'::text, ''::text), '::text'::text, ''::text) AS bdc_column_default_formatted,
    f.check_constraint,
        CASE
            WHEN ((f.check_constraint)::text = ''::text) THEN ''::text
            ELSE format('(%s)'::text, lip.bdc_strip_prefix((f.check_constraint)::text, 'check '::text))
        END AS check_constraint_formatted,
    COALESCE((c.check_clause)::character varying, ''::character varying) AS bdc_check_clause_formatted,
    c.check_constraint_name
   FROM ((lip.bdd_table t
     JOIN lip.bdd_field_table f ON ((f.jid_bdd_table = t.id_bdd_table)))
     JOIN lip.bdc_field_table_list c ON ((((c.table_name)::name = t.table_name) AND ((c.column_name)::name = f.field_name))));


ALTER TABLE lip."bdd_field_table.details" OWNER TO postgres;

--
-- Name: bdd_function; Type: TABLE; Schema: lip; Owner: postgres
--

CREATE TABLE lip.bdd_function (
    id_bdd_function integer NOT NULL,
    source_code text DEFAULT ''::text NOT NULL,
    function_name name DEFAULT ''::name NOT NULL,
    CONSTRAINT bdd_function_function_name_check CHECK ((length((function_name)::text) > 2))
);


ALTER TABLE lip.bdd_function OWNER TO postgres;

--
-- Name: bdd_view; Type: TABLE; Schema: lip; Owner: postgres
--

CREATE TABLE lip.bdd_view (
    id_bdd_view integer NOT NULL,
    view_name name NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    source_code text NOT NULL
);


ALTER TABLE lip.bdd_view OWNER TO postgres;

--
-- Name: pk_bdd_function_sequence_b; Type: SEQUENCE; Schema: lip; Owner: postgres
--

CREATE SEQUENCE lip.pk_bdd_function_sequence_b
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 999999
    CACHE 1;


ALTER TABLE lip.pk_bdd_function_sequence_b OWNER TO postgres;

--
-- Data for Name: bdc_source_code; Type: TABLE DATA; Schema: lip; Owner: lip_migration_user
--

COPY lip.bdc_source_code (object_name, source_code) FROM stdin;
\.
COPY lip.bdc_source_code (object_name, source_code) FROM '$$PATH$$/3457.dat';

--
-- Data for Name: bdd_domain; Type: TABLE DATA; Schema: lip; Owner: lip_migration_user
--

COPY lip.bdd_domain (id_bdd_domain, domain_name, description, source_code) FROM stdin;
\.
COPY lip.bdd_domain (id_bdd_domain, domain_name, description, source_code) FROM '$$PATH$$/3460.dat';

--
-- Data for Name: bdd_field_table; Type: TABLE DATA; Schema: lip; Owner: lip_migration_user
--

COPY lip.bdd_field_table (id_bdd_field_table, jid_bdd_table, field_name, data_type, not_null, default_constraint, check_constraint) FROM stdin;
\.
COPY lip.bdd_field_table (id_bdd_field_table, jid_bdd_table, field_name, data_type, not_null, default_constraint, check_constraint) FROM '$$PATH$$/3459.dat';

--
-- Data for Name: bdd_function; Type: TABLE DATA; Schema: lip; Owner: postgres
--

COPY lip.bdd_function (id_bdd_function, source_code, function_name) FROM stdin;
\.
COPY lip.bdd_function (id_bdd_function, source_code, function_name) FROM '$$PATH$$/3461.dat';

--
-- Data for Name: bdd_table; Type: TABLE DATA; Schema: lip; Owner: lip_migration_user
--

COPY lip.bdd_table (id_bdd_table, table_name, notes) FROM stdin;
\.
COPY lip.bdd_table (id_bdd_table, table_name, notes) FROM '$$PATH$$/3458.dat';

--
-- Data for Name: bdd_view; Type: TABLE DATA; Schema: lip; Owner: postgres
--

COPY lip.bdd_view (id_bdd_view, view_name, notes, source_code) FROM stdin;
\.
COPY lip.bdd_view (id_bdd_view, view_name, notes, source_code) FROM '$$PATH$$/3463.dat';

--
-- Name: pk_bdd_function_sequence_b; Type: SEQUENCE SET; Schema: lip; Owner: postgres
--

SELECT pg_catalog.setval('lip.pk_bdd_function_sequence_b', 2, true);


--
-- Name: bdc_source_code bdc_source_code_pkey; Type: CONSTRAINT; Schema: lip; Owner: lip_migration_user
--

ALTER TABLE ONLY lip.bdc_source_code
    ADD CONSTRAINT bdc_source_code_pkey PRIMARY KEY (object_name);


--
-- Name: bdd_field_table bdd_field_table_pkey; Type: CONSTRAINT; Schema: lip; Owner: lip_migration_user
--

ALTER TABLE ONLY lip.bdd_field_table
    ADD CONSTRAINT bdd_field_table_pkey PRIMARY KEY (id_bdd_field_table);


--
-- Name: bdd_table bdd_table_pkey; Type: CONSTRAINT; Schema: lip; Owner: lip_migration_user
--

ALTER TABLE ONLY lip.bdd_table
    ADD CONSTRAINT bdd_table_pkey PRIMARY KEY (id_bdd_table);


--
-- Name: bdd_field_table fk_bdd_field_table_jid_bdd_table; Type: FK CONSTRAINT; Schema: lip; Owner: lip_migration_user
--

ALTER TABLE ONLY lip.bdd_field_table
    ADD CONSTRAINT fk_bdd_field_table_jid_bdd_table FOREIGN KEY (jid_bdd_table) REFERENCES lip.bdd_table(id_bdd_table);


--
-- Name: DATABASE lip_01; Type: ACL; Schema: -; Owner: postgres
--

REVOKE CONNECT,TEMPORARY ON DATABASE lip_01 FROM PUBLIC;
GRANT CONNECT,TEMPORARY ON DATABASE lip_01 TO lip_migration_role;
GRANT CONNECT,TEMPORARY ON DATABASE lip_01 TO lip_app_role;
GRANT CONNECT,TEMPORARY ON DATABASE lip_01 TO lip_ro_role;


--
-- Name: SCHEMA lip; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA lip TO lip_migration_role;
GRANT USAGE ON SCHEMA lip TO lip_app_role;


--
-- Name: TABLE bdc_function_list; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdc_function_list TO lip_app_role;
GRANT SELECT ON TABLE lip.bdc_function_list TO lip_ro_role;


--
-- Name: TABLE bdc_source_code; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdc_source_code TO lip_app_role;
GRANT SELECT ON TABLE lip.bdc_source_code TO lip_ro_role;


--
-- Name: TABLE bdc_view_list; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdc_view_list TO lip_app_role;
GRANT SELECT ON TABLE lip.bdc_view_list TO lip_ro_role;


--
-- Name: TABLE bdd_domain; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdd_domain TO lip_app_role;
GRANT SELECT ON TABLE lip.bdd_domain TO lip_ro_role;


--
-- Name: TABLE bdd_field_table; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdd_field_table TO lip_app_role;
GRANT SELECT ON TABLE lip.bdd_field_table TO lip_ro_role;


--
-- Name: TABLE bdd_table; Type: ACL; Schema: lip; Owner: lip_migration_user
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lip.bdd_table TO lip_app_role;
GRANT SELECT ON TABLE lip.bdd_table TO lip_ro_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: lip; Owner: lip_migration_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE lip_migration_user IN SCHEMA lip GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES  TO lip_app_role;
ALTER DEFAULT PRIVILEGES FOR ROLE lip_migration_user IN SCHEMA lip GRANT SELECT ON TABLES  TO lip_ro_role;


--
-- PostgreSQL database dump complete
--

