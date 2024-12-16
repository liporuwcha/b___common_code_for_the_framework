# b_common_code_for_the_framework

***liporuwcha namespace "b - common code for the framework"***

 ![work-in-progress](https://img.shields.io/badge/work_in_progress-yellow)
 ![rustlang](https://img.shields.io/badge/rustlang-orange)
 ![postgres](https://img.shields.io/badge/postgres-orange)
 ![b_common_code_for_the_framework](https://bestia.dev/webpage_hit_counter/get_svg_image/238074482.svg)

## Description

With the namespace "b" I will have a working framework that works with database, server and client.
But without any content. It is the basis for later content.

## ba - database core (common code)

Here is the code for starting and configuring the Postgres server.

### baa - database servers  

For development I will have Postgres in a Linux container. I will add this container to the [Podman pod for development CRUSTDE](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod). I will use the prepared script in [crustde_install/pod_with_rust_pg_vscode](https://github.com/CRUSTDE-ContainerizedRustDevEnv/crustde_cnt_img_pod/tree/main/crustde_install/pod_with_rust_pg_vscode).  
This postgres server listen to localhost port 5432. The administrator user is called "admin" and the default password for now is well known.  
To access Postgres server from windows, I will use VSCode and connect remotely from Windows to CRUSTDE and forward the port 5432.

On google cloud virtual machine my hobby server is so small, that I installed it remotely on Linux.  
Run from Windows git-bash :

```bash
ssh username@server_url
sudo apt install postgresql postgresql-client
```

### bab - psql the postgres client

[psql](https://www.postgresql.org/docs/current/app-psql.html) is the command line utility for managing postgres.  
It is very effective.
Auto-completion works ! But not for fields in a table.
History works !
Every sql statement must end with semicolon !
If the result is long, use PgUp, PgDn, End, Home keys to scroll,
then exit scroll with "\q".

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

### bac - databases

One server can have many databases.  


### bad - backup and restore

For backup run this from the VSCode terminal inside the project folder.

```bash
pg_dump -F t -U admin -h localhost -p 5432 database_name > db_backup/database_name_2022_11_09.tar
```

For restore run this from the VSCode terminal inside the project folder.

```bash
createdb -U admin -h localhost -p 5432 database_name; 
pg_restore -c -U admin -h localhost -p 5432 -d database_name db_backup/database_name_2022_11_09.tar
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
