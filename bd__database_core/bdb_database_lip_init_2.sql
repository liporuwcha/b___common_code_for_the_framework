-- bdb_database_lip_init_2.sql
-- https://stackoverflow.com/questions/29420706/best-practices-for-user-permissions-in-postgresql
-- the administrator user `postgres` will be the owner of the database
-- run under user `postgres` on database `lip_01`

revoke create on schema public from public;
create schema if not exists lip;
alter database lip_01 set search_path to lip;
create user lip_migration_user with encrypted password '***';
create user lip_app_user with encrypted password '***';
create user lip_ro_user with encrypted password '***';
grant usage, create on schema lip to lip_migration_role;
grant usage on schema lip to lip_app_role;
grant all on all sequences in schema lip to lip_migration_role;
grant usage, select on all sequences in schema lip to lip_app_role;
grant lip_migration_role to lip_migration_user;
grant lip_app_role to lip_app_user;
grant lip_ro_role to lip_ro_user;
