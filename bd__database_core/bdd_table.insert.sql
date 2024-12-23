create or replace function "bdd_table.insert"(i_table_name name, i_notes text)
returns text 
as $function$
-- insert into bdd_table table.
-- select "bdd_table.insert"('bdd_view2','')
declare
    v_id_bdd_table integer;
    v_text text;
    v_record record;
begin
    insert into bdd_table ( id_bdd_table, table_name, notes )
    values ( bdc_random_int(), i_table_name, i_notes )
    returning *
    into v_record;

    return format('Table inserted %s %s',v_record.id_bdd_table, i_table_name);

end; $function$ language plpgsql;
