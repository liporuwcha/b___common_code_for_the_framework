select bdc_function_migrate('bdc_strip_prefix',
$source_code$

create or replace function "bdc_strip_prefix"(i_string text, i_prefix text)
returns text 
as $function$
-- Returns a string with the prefix removed
-- select bdc_strip_prefix('123456789','123')
-- select bdc_strip_prefix('123456789','1')
-- select bdc_strip_prefix('123456789','') - returns the same string
-- select bdc_strip_prefix('123456789','999') - returns the same string
-- select bdc_strip_prefix('123456789','123456789') - returns empty string
-- select bdc_strip_prefix('12345','123456789') - returns the same string
-- select bdc_strip_prefix('123456789',null) - returns the same string
-- select bdc_strip_prefix(null,'123') - returns null
begin
if starts_with(i_string, i_prefix) then
    return substring(i_string, length(i_prefix)+1);
else
    return i_string;
end if;

end; $function$ language plpgsql;

$source_code$);
