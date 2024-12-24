create or replace function "bdd_view.update"(i_view_name name, i_source_code text, i_notes text)
returns text 
as $function$
-- update bdd_view table.
-- select "bdd_view.update"('bdd_view','')
declare
    v_record record;
begin
    update bdd_view 
    set source_code=i_source_code, notes=i_notes
    where view_name=i_view_name
    returning *
    into v_record;

    return format('Table updated %s %s',v_record.id_bdd_view, i_view_name);

end; $function$ language plpgsql;
