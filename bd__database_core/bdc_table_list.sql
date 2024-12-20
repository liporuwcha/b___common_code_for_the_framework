select bdc_view_migrate('bdc_table_list',
$source_code$

create or replace view bdc_table_list
as
-- only lip tables
-- select * from bdc_table_list ;

select
  t.table_name
from
  information_schema.tables t
where t.table_schema='lip'
and table_type='BASE TABLE'

$source_code$);
