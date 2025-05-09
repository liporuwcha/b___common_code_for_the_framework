# b___common_code_for_the_framework

***liporuwcha namespace b___ common code for the framework***

 ![logo](https://github.com/liporuwcha/.github/blob/main/images/logo/logo_liporuwcha.png)  
 liporuwcha is a "GitHub organization" that groups [multiple repositories](https://github.com/orgs/liporuwcha/repositories?q=sort%3Aname-asc) together

 ![work-in-progress](https://img.shields.io/badge/work_in_progress-yellow)
 ![rustlang](https://img.shields.io/badge/rustlang-orange)
 ![postgres](https://img.shields.io/badge/postgres-orange)
 ![License](https://img.shields.io/badge/license-MIT-blue.svg)
 ![b_common_code_for_the_framework](https://bestia.dev/webpage_hit_counter/get_svg_image/238074482.svg)

## Framework project

Sometimes I will abbreviate the project name `liporuwcha` to just `lip` for sake of brevity.  
With the namespace "b" I will have a working framework that works with database, server and client.
But without any content. It is the basis for later content.

## bd__ database core (common code)

Here is the code for starting and configuring the Postgres server.

### bda_ database servers and clients

I will use Postgres all the way. The database is the most important part of the project. I can be productive only if I limit myself to one specific database. There is a lot to learn about a database administration.

#### bda_development environment inside a Linux container

For development I will have Postgres in a Linux container. I will add this container to the [Podman pod for development CRUSTDE](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod). I will use the prepared script in [crustde_install/pod_with_rust_pg_vscode](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod/tree/main/crustde_install/pod_with_rust_pg_vscode).  
This postgres server listens to localhost port 5432. The administrator user is called "postgres" and the default password is well known.  

Inside the container CRUSTDE I can use the client `psql` to work with the Postgres server. For that I need the bash terminal of the CRUSTDE container. I work with VSCode remote-SSH extension to connect to the container. I invoke it like this from git-bash:

```bash
MSYS_NO_PATHCONV=1 code --remote ssh-remote+crustde /home/rustdevuser/rustprojects
```

VSCode have an integrated terminal where I can work inside the CRUSTDE container easily. this is where I can use `psql`.  

To forward the port 5432 to make it accessible from the parent Debian and Windows OS, I can open [secure SSH tunneling](https://builtin.com/software-engineering-perspectives/ssh-port-forwarding) from Windows git-bash:

```bash
sshadd crustde
ssh rustdevuser@localhost -p 2201 -L 5432:localhost:5432
```

Then, I can use the localhost port 5432 from Windows. I can use `VSCode extension SQLTools` to send SQL statements to the Postgres server.

#### bda_testing environment

#### bda_production environment on Debian in VM

On google cloud virtual machine my hobby server is so small, that I avoided using the Postgres container. Instead I installed Postgres directly on Debian.  
Run from Windows git-bash :

```bash
sshadd server_url
ssh username@server_url
sudo apt install postgresql postgresql-client
```

#### bda_psql the postgres client

[psql](https://www.postgresql.org/docs/current/app-psql.html) is the command line utility for managing postgres.  
It is very effective.
Auto-completion works, but not for fields in a table.
History works. Every sql statement must end with semicolon.
If the result is long, use PgUp, PgDn, End, Home keys to scroll, then exit scroll with "\q".

There exist some administrative shortcuts, but I will avoid them and use proper SQL instead. I don't like upper case style of SQL, so I will force everything lower case.

```psql
\l     List database
\c     Current database
\c dbname   Switch connection to a new database
\dt    List tables
\dv    List views
\df    List functions
\q     Exit psql shell

-- every sql statement must end with semicolon:
select * from webpage;
select * from hit_counter h;
```

#### bda_VSCodeDatabaseClient

I need to easily change data in a grid. I found this VSCode extension [DatabaseClient from Weijan Chen](https://marketplace.visualstudio.com/items?itemName=cweijan.vscode-database-client2) that does it well. I will remove the extension SQLTools.

The extension creates a connection over tcp to the Postgres server. If needed, I use SSH tunneling when I use containers.

Because of the problem of parsing Postgres $$ string delimiters I avoid parsing in the VSCode Database Client extension.  
For all my needs in Postgres, I use now the command `mysql.runSQLWithoutParse` instead of the default `mysql.runSQL`. I can select all or select a part of my sql code, and press `ctrl+enter`.  
In VSCode-Preferences-Keyboard shortcut from the `command`: `mysql.runSQL` remove the keybinding `key`: `ctrl+enter`.  
Then on `command`: `mysql.runSQLWithoutParse` add the same keybinding `key`: `ctrl+enter`,  
and the When expression copied from the original shortcut:   `when`: `config.database-client.executeCursorSQLByShortcut && editorLangId =~ /sql|cql|postgres/ || config.database-client.executeCursorSQLByShortcut && resourceFilename =~ /.dbclient-js$/ || editorHasSelection && editorLangId =~ /sql|cql|postgres/ || editorHasSelection && resourceFilename =~ /.dbclient-js$/`.

I often want to close the sql `Result pane`. Usually the Result pane is in `Editor Group 2`. I press `ctrl+2` and `ctrl+w` to close it.  

To open and close the terminal in VSCode I use my keybinding `ctrl+č` to `workbench.action.terminal.toggleTerminal`.

### bdb_ postgres databases

One Postgres server can have many Postgres databases.

### bdb_schema

Postgres automatically creates the schema `public` for new database. I will create a new specific schema `lip` instead as the default schema.

### bdb_users and bdb_role

PostgreSQL uses the [concept of roles](https://neon.tech/postgresql/postgresql-administration/postgresql-roles) to represent users (with login privileges) and groups.  
Roles are valid across the entire PostgreSQL server, so they don’t need to be recreated for each database.  
We need a `lip_migration_user` that can create database objects. In postgres they name this concept `superuser`.  
Than we will make a role named `lip_app_user` that can work with the data, but cannot administer the database.
An one more role `lip_ro_user` that can read the data, but cannot change it.

### dbd_owner

It is very important in PostgreSQL who is the owner of the object. Only the owner or superuser can alter the object. All objects in the `lip` database will have the owner `lip_migration_user`.

### bdb_migration

The sql language or postgres don't have anything useful for database migration. Migration is the term used when we need to update the schema, add tables or columns, views or functions. This is not just an option, the migration is unavoidable when we iteratively develop a database application. Third party solutions are just terrible.
So the first thing I did, is to create a small set of views and functions that can be called a "basic migration mechanism". It is super simplistic, made entirely inside the postgres database, but good enough for this tutorial.  
Can you imagine that postgres does not store the original code for views and functions? It is or distorted or just partial. Unusable. So the first thing I need is a table to store the exact installed source code `bdc_source_code`. That way I can check if the "new" source code is already installed and not install unchanged code. This is not perfect because I cannot (easily) forbid to install things manually and not store it in `bdc_source_code`, but that is "bad practice" and I hope all developers understand the importance of discipline when working with a delicate system like a database.
After I update database objects in development, I need to be able to repeat this changes as a migration in the production database.  
I will use backup/restore to revert the developer database to the same situation as the production database and test the migration many times. The migrate command is a bash script. It is omnipotent. I just run that script and it must do the right thing in any situation.  
There are different objects that need different approaches.  
A table is made of columns/fields. The first column is usually the primary key of the table. I start creating the new table only with the first column. It is a new empty table, it takes no time at all. It is very difficult later to change this first column, so I will not upgrade this automatically.  
The rest of the columns are installed one by one. Why? Because if one column changes later, we have a place to change it independently from other columns. There are limits what and how we can change it when it contains data, but that is the job of the developer: to understand the data and the mechanisms how to upgrade. It is not easy and cannot be automated.  Usually it is made in many steps, not just in one step. Complicated.  
When writing code always be prepared that a column can be added anytime. This must not disrupt the old code. Deleting or changing a column is much more complicated and needs change to all dependent code.
Unique keys and foreign keys MUST be single-column for our sanity. Technically is very simple to do a multi-column key, but maintaining that code in a huge database is terrible. Sooner or later also your database will become huge. That is just how evolution works. Unstoppable.  
One table can have foreign keys to another table. The later must be installed first. The order of installing objects is important.  
All modification of data must be done with sql functions. Never call update/insert/delete directly from outside of the database. Slowly but surely, a different module in another language on another server will need the same functionality and the only way to have it in common is to have it on the database level.
I write my sql code in VSCode. Every object is a separate file. This makes it easy to use Git as version control. Every file is prepared for the migration mechanism and can be called from psql or within VSCode with the extensions SQLTools.  
Then I write bash scripts that call psql to run this sql files in the correct order. That is my super-simple "migration mechanism". Good enough.

Postgres sometimes adds type notation to my code for default and check constraint on a table field. That makes it hard to compare my definition with what is installed in the database. It does not ass it for varchar, integer, but for text and name,... It adds also some round brackets. For now I must type in my definition exactly how postgres stores it. Examples: `check ((length((table_name)::text) > 2))`  or  `default ''::name`

After some initial coding with sql files in VSCode, the definitions and code of all objects will stay inside the database. Then sql functions will provide installation and migration utilities. This is good for maintainability and open-source.

#### bdb_database_lip_init

My first development database will be `lip_01`.
Database creation and initialization is split into 4 scripts.

- first we need to create the database:  
run under user `postgres` on database `postgres`  
[bdb_database_lip_init_1.sql](bd_database_core/bdb_database_lip_init_1.sql)

- second create the new default schema and users:  
run under user `postgres` on database `lip_01`  
[bdb_database_lip_init_2.sql](bd_database_core/bdb_database_lip_init_2.sql)

- third grant permissions to roles:  
run under user `lip_migration_user` on database `lip_01`  
[bdb_database_lip_init_3.sql](bd_database_core/bdb_database_lip_init_3.sql)

- forth seed lip database for migration  
run under user `lip_migration_user` on database `lip_01`  
[bdb_database_lip_init_4.sql](bd_database_core/bdb_database_lip_init_4.sql)  
Then we need to initialize the database. In this code there will be the SQL statement to prepare a `seed lip database` that can be then upgraded and work with. This initialization uses knowledge from other parts of the project, so it will be repeated in some way.

#### bdb_postgres_container

To work inside the postgres container open the bash shell with podman exec:

```bash
podman exec -it crustde_postgres_cnt /bin/bash
```

Then I can use pg commands to work with the postgres server:

```bash
# we login as root@crustde_pod:/#
# if needed install nano
apt update && apt upgrade
apt install nano
# change interactive user to superuser `postgres`
su postgres
# postgres@crustde_pod:/$
# server version
pg_config --version
# PostgreSQL 15.10 (Debian 15.10-1.pgdg120+1)
# client version
psql --version
```

#### bdb_postgres_database_cluster

Postgres likes to have databases separated in "database clusters" on the same server. Because backups and `PITR` `point in time recovery` work on the whole cluster thing and not on a database level.  
Confusing nomenclature: "Database cluster" or "instance" or "data directory" or "data area".
Old original cluster is in `/var/lib/postgresql/data`, but it was not created with `pg_createcluster`. Bad.  

Remove this cluster as soon as possible, before it has any data inside.
This cluster is created even after `apt upgrade`.
First check with psql:

```bash
# connect on default port 5432
su postgres
psql
# if this cluster exists, stop it and remove it
\q
pg_ctl stop -D /var/lib/postgresql/data
```

Debian has some wrapper commands for better work with database clusters.
My instance_name will be `lip_dev_01`.

```bash
pg_createcluster --port=6000 15 lip_dev_01 
# created the folder /var/lib/postgresql/15/lip_dev_01 on port 6000
# we can write the cluster name inside postgresql.conf
pg_ctlcluster 15 lip_dev_01 start 
# list the database clusters that were created with pg_createcluster
pg_lsclusters 
#Ver Cluster     Port Status Owner    Data directory                    Log file
#15  lip_dev_01  5433 online postgres /var/lib/postgresql/15/lip_dev_01 /var/log/postgresql/postgresql-15-lip_dev_01.log
#15  lip_dev_02  5434 online postgres /var/lib/postgresql/15/lip_dev_02 /var/log/postgresql/postgresql-15-lip_dev_02.log
```

The `postgresql.conf` in Debian is in the folder `/etc/postgresql/15/dev_01`.

Every cluster gets its own port, so we can connect to them separately.
The local user `postgres` can connect over local Unix domain socket connections.
Create a password for user `postgres` in psql:

```bash
# change interactive user to superuser `postgres`
su postgres
psql -U postgres -p 5433
#psql (15.10 (Debian 15.10-1.pgdg120+1))
\password postgres
#Enter new password for user "postgres": ***
#Enter it again: ***

# check the cluster name
SHOW cluster_name;
# cluster_name = '15/dev_01'
\q
```

I will not use the default `cluster` on port 5432, because it makes it confusing what cluster are we connected.

#### clusters for dev, test and prod instances

The name of the cluster and the folder of the cluster is created the same by the `pg_createcluster` command.  
For development I will use a dev suffix like: `lip_dev_01`, `lip_dev_02`, `lip_test_01`, `lip_prod_01`,...

#### backup or dump

Postgres has 2 different methods for backups.  
The word `dump` is used to create sql code that can recreate the database. This is called also "logical backup".  
The dump can be created for a single database.

`Backup` or `base_backup` is "physical backup" and it makes copies of the files for database and for transactions.
The backup can be done only for the whole "cluster". This can be used for "point in time recovery" PITR.

#### bdb_dump

For this dump or "logitech backup" run this in bash terminal inside the container.

```bash
mkdir db_backup
pg_dump -F t -U postgres -h localhost -p 5433 lip_01 > db_backup/lip_01_2025_01_21.tar
ls db_backup
```

Run in the parent OS to download from the container over ssh:

```bash
# download backup over ssh for development and testing
scp rustdevuser@crustde:/home/rustdevuser/db_backup/lip_01_2024_12_24.tar db_backup/lip_01_2024_12_24.tar
```

The dump file is just gz compressed plain text of sql code. It is easily searchable with a standard text editor. Nice for my search-all-and replace approach!

#### bdb_restore from dump

For restore run this from the VSCode terminal inside the project folder when connected to CRUSTDE.

```bash
# first create the roles, users and database manually 
# run the sql script from bd__database_core/bdb_database_lip_init_1.sql
# run the sql script from bd__database_core/bdb_database_lip_init_2.sql
pg_restore -c -U postgres -h localhost -p 5433 -d lip_01 db_backup/lip_01_2025_01_20.tar
```

### bdb_basebackup

The "physical backup" in Postgres is called `pg_basebackup`.  
It can make the backup only of the whole "database cluster". Cannot do the backup of a single database.  
This kind of backup allows to make PITR "point in time recovery".



### bdb_Point_In_Time_Recovery PITR

<https://pgdash.io/blog/postgres-incremental-backup-recovery.html>  
<https://www.scalingpostgres.com/tutorials/postgresql-backup-point-in-time-recovery/>  

The ability to use PITR "point in time recovery" is not enabled by default.

```bash
# open the bash inside the postgres container as root
podman exec -it crustde_postgres_cnt /bin/bash
```

```bash
# make folder as postgres@crustde_pod:/$
su postgres
mkdir -p /var/lib/postgresql/15_archive_wal/dev_01
nano /etc/postgresql/15/dev_01/postgresql.conf
```

Find and modify these 3 lines:

```plaintext
  wal_level = replica
  archive_mode = on # (change requires restart)
  archive_command = 'test ! -f /var/lib/postgresql/15_archive_wal/dev_01/%f && cp %p /var/lib/postgresql/15_archive_wal/dev_01/%f'
```

```bash
exit
# return to root@crustde_pod:/#
pg_ctlcluster 15 dev_01 start 
```


1. Close the WAL of the database cluster

`pg_ctl stop` closed the whole container???




### bdc_ database lowest components

A translation layer between `lip` code and the postgres low code and objects.
I want to isolate the postgres low code and objects in this module. They use strange names.
In `lip` I will never use directly postgres components, but always this translation layer.

[bdc_role_list.sql](bd__database_core/bdc_role_list.sql)  

[bdc_view_list.sql](bd__database_core/bdc_view_list.sql)  
[bdc_view_migrate.sql](bd__database_core/bdc_view_migrate.sql)  

[bdc_function.list.sql](bd__database_core/bdc_function.list.sql)  
[bdc_function_migrate.sql](bd__database_core/bdc_function_migrate.sql)  
[bdc_function_drop.sql](bd__database_core/bdc_function_drop.sql)  

#### bdc_source_code table(object_name, source_code)

Postgres server does not store the exact source code as I install views and functions.
I want to be able to check if the source code has changed to know if it needs to be installed.
Therefore I must store my source code in a table, where I can control what is going on.

### bdd_ definitions for `lip` database objects

A `lip` project contains definitions of tables, fields, relations, views, functions, methods, user interface,...
This definitions are stored in the same database for performance and migration.  
More than one team can work simultaneously on a `lip project`, therefore I cannot use sequence for this table primary keys. The ids must have ranges per project. Every range will have a million numbers. That would be enough. It means I can have 2000 projects with 1 million numbers each.
The framework range is the first million numbers.

I like to use `dot` in function names, that is a nice standard. Postgres names with dots must be delimited with double quotes. Maybe it isn't

#### bdd_unit

A `lip` unit is the container of definitions of lip objects.
They are ordered in a tree structure.

`id_unit` int
name
parent_id_unit
notes

Every object will have a reference, relation, join to bdd_unit with the field `jid_unit`.
Different projects will have a defined range od `id_unit` so that more teams can develop simultaneously.
The basic framework project will have the range from 1-999999.

#### bdd_domain user-defined data type

In postgres `domain` is a user-defined data type. It can have constraints that restrict its valid values.

```sql
CREATE DOMAIN dm_positive_integer AS integer CHECK (VALUE > 0);
CREATE DOMAIN dm_system_name AS varchar(100) not null integer check (length(value) > 0);
CREATE DOMAIN dm_notes AS text not null default '';
```

#### bdd_table

Definition of a table.
[bdd_table_create.sql](bd__database_core/bdd_table_create.sql)

function:
bdd_table.insert
bdd_table.migrate

#### bdd_field_table

Definition of a field in the table.
I hope I will use auto-complete when writing sql code. For that purpose I will use some naming rules:
The `id` field of a table starts with `id_` and continues with the full table name like `id_bdd_table`.
The relation/reference/join field will add the prefix `j` like `jid_bdd_table`.

id_field_table
jid_bdd_table
name
field_type


#### bdd_data_type

Postgres has many data_types. I will try to limit this types for `lip` projects.

- `integer`, also known as INT, is one of the most commonly used data types in PostgreSQL. It stores whole numbers (i.e., numbers without decimal points) and requires 4 bytes of storage. The range of values it can store is between -2,147,483,648 to 2,147,483,647.
- `name` is a 63 byte (varchar) type used for storing system identifiers.
- `varchar(n)` is variable-length character type to store strings with the defined length. Max length is 8000.
- `text` is variable-length character type with no specific length limit.
- `boolean` Stores true, false, and null values.

## bj__ server core (common code)

## bs__ client core (common code)

## Open-source and free as a beer

My open-source projects are free as a beer (MIT license).  
I just love programming.  
But I need also to drink. If you find my projects and tutorials helpful, please buy me a beer by donating to my [PayPal](https://paypal.me/LucianoBestia).  
You know the price of a beer in your local bar ;-)  
So I can drink a free beer for your health :-)  
[Na zdravje!](https://translate.google.com/?hl=en&sl=sl&tl=en&text=Na%20zdravje&op=translate) [Alla salute!](https://dictionary.cambridge.org/dictionary/italian-english/alla-salute) [Prost!](https://dictionary.cambridge.org/dictionary/german-english/prost) [Nazdravlje!](https://matadornetwork.com/nights/how-to-say-cheers-in-50-languages/) 🍻

[//bestia.dev](https://bestia.dev)  
[//github.com/bestia-dev](https://github.com/bestia-dev)  
[//bestiadev.substack.com](https://bestiadev.substack.com)  
[//youtube.com/@bestia-dev-tutorials](https://youtube.com/@bestia-dev-tutorials)  
