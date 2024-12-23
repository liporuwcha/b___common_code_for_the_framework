create or replace function "bdd_table.upsert"(i_table_name name, i_notes text)
returns text 
as $function$
-- Update or insert function into bdd_table table.
-- select "bdd_table.upsert"('bdd_view','')
declare
    v_id_bdd_table integer;
    v_text text;
begin

    select p.id_bdd_table
    from   bdd_table p
    where  p.table_name = i_table_name
    into v_id_bdd_table;

    if v_id_bdd_table is null THEN
        select "bdd_table.insert"(i_table_name, i_notes) into v_text;
        return format('%s',v_text);
    else
        select "bdd_table.update"(i_table_name, i_notes) into v_text;
        return format('%s',v_text);
    end if;
end; $function$ language plpgsql;
