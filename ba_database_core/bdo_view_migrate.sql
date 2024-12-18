select bdo_function_migrate('bdo_view_migrate',
$source_code$

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

$source_code$);
