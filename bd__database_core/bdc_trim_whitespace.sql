select "bdd_function.upsert_and_migrate"('bdc_trim_whitespace',
$source_code$

create or replace function bdc_trim_whitespace(i_string text)
returns text
-- trim space, newline and tab on both ends
-- select bdc_trim_whitespace() as my_random;
-- select bdc_trim_whitespace(' 123 ');
as $function$
    SELECT trim(i_string,E' \n\r\t'); 
$function$ language sql;

$source_code$);
