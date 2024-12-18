select bdo_view_migrate('bdo_view_list',
$source_code$

create view bdo_view_list
as
-- only public views
-- select * from bdo_view_list ;

select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='public'
order by t.table_name;

$source_code$);
