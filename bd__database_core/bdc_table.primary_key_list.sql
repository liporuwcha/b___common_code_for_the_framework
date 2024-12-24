create or replace view "bdc_table.primary_key_list"
as
-- only lip views
-- select * from "bdc_table.primary_key_list" ;

select constraint_name , table_name
from information_schema.table_constraints 
where constraint_schema='lip' and constraint_type = 'PRIMARY KEY';