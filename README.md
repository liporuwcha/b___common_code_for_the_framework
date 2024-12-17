# b_common_code_for_the_framework

***liporuwcha namespace "b - common code for the framework"***

 ![work-in-progress](https://img.shields.io/badge/work_in_progress-yellow)
 ![rustlang](https://img.shields.io/badge/rustlang-orange)
 ![postgres](https://img.shields.io/badge/postgres-orange)
 ![b_common_code_for_the_framework](https://bestia.dev/webpage_hit_counter/get_svg_image/238074482.svg)

## Description

Sometimes I will abbreviate the project name `liporuwcha` to just `lip` for sake of brevity.  
With the namespace "b" I will have a working framework that works with database, server and client.
But without any content. It is the basis for later content.

## ba - database core (common code)

Here is the code for starting and configuring the Postgres server.

### baa_ database servers  

I will use Postgres all the way. The database is the most important part of the project. I can be productive only if I limit myself to one specific database. There is a lot to learn about a database administration.

### development server inside a Linux container

For development I will have Postgres in a Linux container. I will add this container to the [Podman pod for development CRUSTDE](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod). I will use the prepared script in [crustde_install/pod_with_rust_pg_vscode](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod/tree/main/crustde_install/pod_with_rust_pg_vscode).  
This postgres server listens to localhost port 5432. The administrator user is called "admin" and the default password is well known.  

Inside the container CRUSTDE I can use the client `psql` to work with the Postgres server. For that I need the bash terminal of the CRUSTDE container. I exclusively work with VSCode remote-SSH extension to connect to the container. I invoke it like this from git-bash:

```bash
MSYS_NO_PATHCONV=1 code --remote ssh-remote+crustde /home/rustdevuser/rustprojects
```

VSCode have an integrated terminal where I can work inside the CRUSTDE container easily. this is where I can use `psql`.  

The same VSCode connection has also the possibility to forward the port 5432, so it is visible from the parent Debian and Windows OS. Or I can open [SSH secure tunneling](https://builtin.com/software-engineering-perspectives/ssh-port-forwarding) and port 5432 forwarding from Windows git-bash:

```bash
sshadd crustde
ssh rustdevuser@localhost -p 2201 -L 5432:localhost:5432
```

Then, I can use the localhost port 5432 from Windows. I can use VSCode extension `SQLTools` or `DBeaver` to send SQL statements to the Postgres server.

### production Postgres on Debian in VM

On google cloud virtual machine my hobby server is so small, that I avoided using the Postgres container. Instead I installed Postgres directly on Debian.  
Run from Windows git-bash :

```bash
sshadd server_url
ssh username@server_url
sudo apt install postgresql postgresql-client
```

### bab_ psql the postgres client

[psql](https://www.postgresql.org/docs/current/app-psql.html) is the command line utility for managing postgres.  
It is very effective.
Auto-completion works ! But not for fields in a table.
History works !
Every sql statement must end with semicolon !
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

-- every sql statement must end with semicolon !
select * from webpage;
select * from hit_counter h;
```

### bac_ databases

One server can have many databases. My first development database will be `lip_01`.

```sql
create database lip_01 owner admin;
select * from pg_database;
```

### bad_ backup and restore

For backup run this from the VSCode terminal inside the project folder when connected to CRUSTDE.

```bash
mkdir db_backup
pg_dump -F t -U admin -h localhost -p 5432 lip_01 > db_backup/lip_01_2024_12_16.tar
ls db_backup
```

For restore run this from the VSCode terminal inside the project folder when connected to CRUSTDE.

```bash
createdb -U admin -h localhost -p 5432 lip_02; 
pg_restore -c -U admin -h localhost -p 5432 -d lip_02 db_backup/lip_01_2024_12_16.tar
```

### bae_ users and roles

PostgreSQL uses the [concept of roles](https://neon.tech/postgresql/postgresql-administration/postgresql-roles) to represent user accounts.  
We need one user to be the administrator. In postgres they name this concept `superuser`. By default it is called `postgres`. I will change this to `admin` because the name is more obvious.  
Than we will make a role named `lip_user` that can work with the data, but cannot administer the database.
An one more role `lip_ro_user` that can read the data, but cannot change it.

```sql
create or replace view bae_roles
as
-- select * from bae_roles ;
select usename as role_name,
  case
     when usesuper and usecreatedb then
       cast('superuser, create database' as pg_catalog.text)
     when usesuper then
        cast('superuser' as pg_catalog.text)
     when usecreatedb then
        cast('create database' as pg_catalog.text)
     else
        cast('' as pg_catalog.text)
  end role_attributes
from pg_catalog.pg_user
order by role_name desc;
```

Just FYI: PostgreSQL automatically creates a schema called `public` for every new database. Whatever object you create without specifying the schema name, PostgreSQL will place it into this `public` schema

```sql
create role admin superuser password '***';
drop role if exists postgres;

create role lip_user login password '***';
grant all
on all tables
in schema "public"
to lip_user;

create role lip_ro_user login password '***';
grant select
on all tables
in schema "public"
to lip_ro_user;

```

## bj - server core (common code)

## bs - client core (common code)

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
