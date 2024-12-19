select bdc_view_migrate('bdc_view_list',
$source_code$

create view bdc_view_list
as
-- only lip_schema views
-- select * from bdc_view_list ;

select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='lip_schema'
order by t.table_name;

$source_code$);
