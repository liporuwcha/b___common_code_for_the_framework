create or replace function "bdd_view.migrate"(i_view_name name)
returns text 
as $function$
-- install the view from bdd into postgres
-- if the view is modified
-- select "bdd_view.migrate"('bdc_view_drop')
declare
    v_source_code text;
    v_text text;
begin

select f.source_code from bdd_view f where f.view_name=i_view_name into v_source_code;

select bdc_view_migrate from bdc_view_migrate(i_view_name, v_source_code) into v_text;

return v_text;
end; $function$ language plpgsql;
