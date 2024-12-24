create or replace function "bdd_view.insert"(i_view_name name, i_source_code text, i_notes text)
returns text 
as $function$
-- insert into bdd_view table.
-- select "bdd_view.insert"('bdd_view2','','')
declare
    v_id_bdd_view integer;
    v_text text;
    v_record record;
begin
    insert into bdd_view ( id_bdd_view, view_name, source_code, notes )
    values ( bdc_random_int(), i_view_name, i_source_code, i_notes )
    returning *
    into v_record;

    return format('Table inserted %s %s',v_record.id_bdd_view, i_view_name);

end; $function$ language plpgsql;
