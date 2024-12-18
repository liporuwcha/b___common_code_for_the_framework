select bdf_function_create_or_replace('bdf_function_create_or_replace',
$source_code$

create or replace function bdf_function_create_or_replace(i_object_name name, i_source_code text)
returns text 
as
-- checks if the function is already installed
-- if is equal, nothing happens
-- else drop the old and install the new function
$$
declare
   -- use only lowercase names, for later search and order as utf-8. No collation for technical strings.
   i_object_name name = lower(i_object_name);
    -- i_definition must allow uppercase

   v_old_definition text;
   v_void text;
begin

      if exists(select * from bdf_function_list p where p.routine_name=i_object_name) then
         select bdf_function_drop(i_object_name) into v_void;
      end if;

      execute i_definition;

      return format('Inserted function: %I', i_object_name);
   else
  


   end if;
return format('Up to date function: %I', i_object_name);
end;
$$ language plpgsql;

$source_code$);
