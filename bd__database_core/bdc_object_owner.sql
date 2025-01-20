create or replace view "bdc_object_owner"
as
-- only lip functions
-- select * from "bdc_object_owner" where object_owner != 'lip_migration_user'
SELECT 
  c.relname as "object_name",
  CASE c.relkind 
  	WHEN 'r' THEN 'table' 
  	WHEN 'v' THEN 'view' 
  	WHEN 'm' THEN 'materialized view' 
  	WHEN 'i' THEN 'index' 
  	WHEN 'S' THEN 'sequence' 
  	WHEN 't' THEN 'TOAST table' 
  	WHEN 'f' THEN 'foreign table' 
  	WHEN 'p' THEN 'partitioned table' 
  	WHEN 'I' THEN 'partitioned index' 
    else cast(c.relkind as text)
    END as "object_type",
  pg_catalog.pg_get_userbyid(c.relowner) as "object_owner",
n.nspname as "schema"
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace and n.nspname='lip'

UNION ALL

select p.proname as "object_name",
  CASE p.prokind 
  	WHEN 'f' THEN 'function' 
    ELSE CAST(p.prokind as text)
    END as "object_type",
pg_catalog.pg_get_userbyid(p.proowner) as "object_owner",
 n.nspname as "schema"
from pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace and n.nspname='lip'

ORDER BY "object_name";
