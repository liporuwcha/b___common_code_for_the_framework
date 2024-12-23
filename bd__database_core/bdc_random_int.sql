create or replace function bdc_random_int()
returns integer
-- inline scalar function ( must be sql language)
-- random from 1 to 2147483646, 
-- that is max positive for the data type integer
-- select bdc_random_int() as my_random;
-- How to test if the function is inline-able?
-- EXPLAIN (ANALYZE, VERBOSE) SELECT bdc_random_int(),table_name as my_random FROM bdd_table;
as $function$
    select FLOOR(RANDOM()*2147483646::double precision) + 1;
$function$ language sql;
