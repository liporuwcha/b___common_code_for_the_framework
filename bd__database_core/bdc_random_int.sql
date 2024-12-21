select "bdd_function.upsert_and_migrate"('bdc_random_int',
$source_code$

create or replace function bdc_random_int()
returns integer
-- inline scalar function ( must be sql language)
-- random from 1 to 2147483646, 
-- that is max positive for the data type integer
-- select bdc_random_int() as my_random;
as $function$
    SELECT FLOOR(RANDOM()*2147483646) + 1; 
$function$ language sql;

$source_code$);
