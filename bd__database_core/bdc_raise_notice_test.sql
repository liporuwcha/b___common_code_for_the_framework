create or replace function "bdc_raise_notice_test"(i_text text)
returns text 
language plpgsql as $function$
-- test "raise notice"
/*
select "bdc_raise_notice_test"('xxx')
*/
begin

-- in VSCode output choose "Database client" to see this text.
RAISE NOTICE 'Test raise notice: %', i_text;

return i_text;
end; $function$;
