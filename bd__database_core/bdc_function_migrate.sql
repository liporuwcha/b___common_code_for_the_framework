select bdc_function_migrate('bdc_function_migrate',
$source_code$

create function bdc_function_migrate(i_object_name name, i_source_code text)
returns text 
as
-- checks if the function is already installed and if the content of bdc_source_code is different
-- if is equal, nothing happens
-- else drop the old and install the new function
-- finally insert/update into bdc_source_code only if the installation is successful  
$$
declare
   v_old_source_code text;
   v_void text;
begin

   if not exists(select * from bdc_source_code a where a.object_name = i_object_name) then
      if exists(select * from bdc_function_list p where p.routine_name = i_object_name) then
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
         if exists(select * from bdc_function_list p where p.routine_name = i_object_name) then
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
$$ language plpgsql;

$source_code$);
