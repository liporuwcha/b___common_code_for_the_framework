-- bdc_database_lip_init_3.sql
-- https://stackoverflow.com/questions/29420706/best-practices-for-user-permissions-in-postgresql
-- run under user `lip_migration_user` on database `lip_01`

alter default privileges in schema lip_schema
grant select, insert, update, delete on tables to lip_app_role;

alter default privileges in schema lip_schema
grant select on tables to lip_ro_role;