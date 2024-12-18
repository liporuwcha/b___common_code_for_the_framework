create or replace view bde_roles
as
-- select * from bde_roles ;
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