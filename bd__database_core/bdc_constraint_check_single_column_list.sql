select bdc_view_migrate('bdc_constraint_check_single_column_list',
$source_code$

create view bdc_constraint_check_single_column_list
as
-- only lip_schema views
-- select * from bdc_constraint_check_single_column_list ;

select tc.table_name, tc.constraint_name, col.column_name, cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc on cc.constraint_name = tc.constraint_name
join pg_constraint pgc on pgc.conname = cc.constraint_name and pgc.contype = 'c' and array_length(pgc.conkey, 1) = 1
join information_schema.columns col on col.table_schema = tc.table_schema and col.table_name = tc.table_name and col.ordinal_position = ANY(pgc.conkey)
where tc.table_schema='lip_schema' and tc.constraint_type='CHECK'

$source_code$);



