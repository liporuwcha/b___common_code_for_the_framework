create or replace function "bdd_table.update"(i_table_name name, i_notes text)
returns text 
as $function$
-- update into bdd_table table.
-- select "bdd_table.update"('bdd_view','')
declare
    v_record record;
begin
    update bdd_table 
    set notes=i_notes
    where table_name=i_table_name
    returning *
    into v_record;

    return format('Table updated %s %s',v_record.id_bdd_table, i_table_name);

end; $function$ language plpgsql;
