select bdc_view_migrate('bdc_role_list',
$source_code$

create view bdc_role_list
as
-- select * from bdc_role_list ;
select usename as role_name,
  case
     when usesuper and usecreatedb then
       cast('superuser, create database' as pg_catalog.text)
     when usesuper then
        cast('superuser' as pg_catalog.text)
     when usecreatedb then
        cast('create database' as pg_catalog.text)
     else
        cast('' as pg_catalog.text)
  end role_attributes
from pg_catalog.pg_user
order by role_name desc;

$source_code$);