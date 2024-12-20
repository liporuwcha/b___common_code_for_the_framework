select bdc_function_migrate('bdd_table.migrate',
$source_code$

create function "bdd_table.migrate"(i_table_name name)
returns text 
as $function$
-- checks if the table has all the fields
-- if needed it adds the fields 
-- select * from "bdd_table.migrate"('bdd_unit')
declare
    v_row record;
    v_sql text;
    v_sql_fields text;
    v_void text;
    v_id_bdd_table integer;
begin
    -- set the variable for id_bdd_table
    -- the expression will set the variables to NULL if no rows were returned
    select t.id_bdd_table into v_id_bdd_table from bdd_table t where t.table_name = i_table_name;
    if v_id_bdd_table is null then
        -- early return
        return format('Error: Definition for %s is not in bdd_table.', i_table_name);
    end if;

    RAISE NOTICE 'Found definition for %s in bdd_table', i_table_name;

    if not exists(select * from bdc_table_list a where a.table_name=i_table_name) then
        -- if table not exists, create it with all fields in one go.
        -- prepare code for fields
        FOR v_row IN
            select f.field_name, f.data_type, f.not_null, f.default_constraint, f.check_constraint
            from bdd_field_table f
            where f.jid_bdd_table = v_id_bdd_table
        LOOP
            if v_sql_fields != '' then
                v_sql_fields = format(E'%s ,\n', v_sql_fields);
            end if;
            v_sql_fields = format('%s %s %s %s %s %s', v_sql_fields, v_row.field_name, v_row.data_type, v_row.not_null, v_row.default_constraint, v_row.check_constraint);

        END LOOP;

        v_sql = format(E'create table %s (\n%s\n)', i_table_name, v_sql_fields);
        execute v_sql;

        return format(E'executed sql code:\n%s', v_sql);
    else
        -- table exists, what fields don't exist?
        -- prepare code for missing fields
        FOR v_row IN
            select f.field_name, f.data_type, f.not_null, f.default_constraint, f.check_constraint
            from bdd_field_table f
            where f.jid_bdd_table = v_id_bdd_table
            and not exists(select * from bdc_field_table c where c.table_name=i_table_name and c.column_name=f.field_name)
            
        LOOP
            if v_sql_fields != '' then
                v_sql_fields = format(E'%s ,\n', v_sql_fields);
            end if;
            v_sql_fields = format('add column %s %s %s %s %s %s', v_sql_fields, v_row.field_name, v_row.data_type, v_row.not_null, v_row.default_constraint, v_row.check_constraint);

        END LOOP;

        v_sql = format(E'alter table %s \n%s\n;', i_table_name, v_sql_fields);
        --execute v_sql;
        return format(E'executed sql code:\n%s', v_sql);
    end if;
end;
$function$ language plpgsql;

$source_code$);
