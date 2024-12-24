create or replace function "bdd_view.upsert"(i_view_name name, i_source_code text, i_notes text)
returns text 
as $function$
-- Update or insert function into bdd_view table.
-- select "bdd_view.upsert"('bdd_view','')
declare
    v_id_bdd_view integer;
    v_text text;
begin

    select p.id_bdd_view
    from   bdd_view p
    where  p.view_name = i_view_name
    into v_id_bdd_view;

    if v_id_bdd_view is null THEN
        select "bdd_view.insert"(i_view_name, i_source_code, i_notes) into v_text;
        return format('%s',v_text);
    else
        select "bdd_view.update"(i_view_name, i_source_code, i_notes) into v_text;
        return format('%s',v_text);
    end if;
end; $function$ language plpgsql;
