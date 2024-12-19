select bdc_view_migrate('bdc_table_list',
$source_code$

create view bdc_table_list
as
-- only lip_schema tables
-- select * from bdc_table_list ;

SELECT
  t.table_name
FROM
  information_schema.tables t
where t.table_schema='lip_schema'
and table_type='BASE TABLE'

$source_code$);
