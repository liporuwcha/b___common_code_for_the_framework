# b___common_code_for_the_framework

***liporuwcha namespace "b___ common code for the framework"***

 ![work-in-progress](https://img.shields.io/badge/work_in_progress-yellow)
 ![rustlang](https://img.shields.io/badge/rustlang-orange)
 ![postgres](https://img.shields.io/badge/postgres-orange)
 ![b_common_code_for_the_framework](https://bestia.dev/webpage_hit_counter/get_svg_image/238074482.svg)

## Description

Sometimes I will abbreviate the project name `liporuwcha` to just `lip` for sake of brevity.  
With the namespace "b" I will have a working framework that works with database, server and client.
But without any content. It is the basis for later content.

## bd__ database core (common code)

Here is the code for starting and configuring the Postgres server.

### bda_ database servers and clients

I will use Postgres all the way. The database is the most important part of the project. I can be productive only if I limit myself to one specific database. There is a lot to learn about a database administration.

#### bda_development environment inside a Linux container

For development I will have Postgres in a Linux container. I will add this container to the [Podman pod for development CRUSTDE](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod). I will use the prepared script in [crustde_install/pod_with_rust_pg_vscode](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod/tree/main/crustde_install/pod_with_rust_pg_vscode).  
This postgres server listens to localhost port 5432. The administrator user is called "admin" and the default password is well known.  

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

I often want to close the sql Result pane. Usually the Result pane is in Editor Group 2. I press ctrl+2 and ctrl+w to close it.    

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

#### bdb_backup

For backup run this from the VSCode terminal inside the project folder when connected to CRUSTDE.

```bash
mkdir db_backup
pg_dump -F t -U admin -h localhost -p 5432 lip_01 > db_backup/lip_01_2024_12_16.tar
ls db_backup
```

#### bdb_restore

For restore run this from the VSCode terminal inside the project folder when connected to CRUSTDE.

```bash
createdb -U admin -h localhost -p 5432 lip_02; 
pg_restore -c -U admin -h localhost -p 5432 -d lip_02 db_backup/lip_01_2024_12_16.tar
```

### bdc_ database lowest components

A translation layer between `lip` code and the postgres low code and objects.
I want to isolate the postgres low code and objects in this module. They use strange names.
In `lip` I will never use directly postgres components, but always this translation layer.

[bdc_role_list.sql](bd__database_core/bdc_role_list.sql)  

[bdc_view_list.sql](bd__database_core/bdc_view_list.sql)  
[bdc_view_migrate.sql](bd__database_core/bdc_view_migrate.sql)  

[bdc_function_list.sql](bd__database_core/bdc_function_list.sql)  
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
description

Every object will have a reference, relation, join to bdd_unit with the field `jid_unit`.
Different projects will have a defined range od `id_unit` so that more teams can develop simultaneously.
The basic framework project will have the range from 1-999999.

#### bdd_domain user-defined data type

In postgres `domain` is a user-defined data type. It can have constraints that restrict its valid values.

```sql
CREATE DOMAIN dm_positive_integer AS integer CHECK (VALUE > 0);
CREATE DOMAIN dm_system_name AS varchar(100) not null integer check (length(value) > 0);
CREATE DOMAIN dm_description AS text not null default '';
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
