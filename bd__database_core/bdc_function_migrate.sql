create or replace function "bdc_function_migrate"(i_function_name name, i_source_code text)
returns text 
as $function$
-- checks if the function is already installed and if the content of bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdc_source_code only if the installation is successful  
declare
   v_old_source_code text;
   v_void text;

begin

   if not exists(select * from bdc_source_code a where a.object_name = i_function_name) then
      if exists(select * from "bdc_function.list" p where p.routine_name = i_function_name) then
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

end; $function$ language plpgsql;
