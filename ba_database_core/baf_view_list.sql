select a2_migrate_view('bdf_view_list',
$source_code$

create view bdf_view_list
as
-- only public views
-- select * from bdf_view_list ;


select t.table_name::name as view_name
from information_schema.views t
where t.table_schema='public'
order by t.table_name;

$source_code$);
