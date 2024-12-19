-- bdb_database_lip_init_1.sql
-- https://stackoverflow.com/questions/29420706/best-practices-for-user-permissions-in-postgresql
-- run under user `postgres` on database `postgres`

--check the existing databases
select * from pg_database;

create database lip_01;

revoke all on database lip_01 from public;
revoke create on schema public from public;

-- lip_migration_role
create role lip_migration_role with encrypted password '***';
grant connect on database lip_01 to lip_migration_role;
grant temporary on database lip_01 to lip_migration_role;

-- lip_app_role
create role lip_app_role with encrypted password '***';
grant connect on database lip_01 to lip_app_role;
grant temporary on database lip_01 to lip_app_role;

-- lip_ro_role
create role lip_ro_role with encrypted password '***';
grant connect on database lip_01 to lip_ro_role;
grant temporary on database lip_01 to lip_ro_role;