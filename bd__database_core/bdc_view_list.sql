create or replace view "bdc_view_list"
as
-- only lip views
-- select * from "bdc_view_list" ;

select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='lip'
order by t.table_name;
