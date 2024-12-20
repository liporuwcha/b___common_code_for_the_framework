select bdc_function_migrate('bdd_table.migrate_details',
$source_code$

create or replace function "bdd_table.migrate_details"(i_table_name name)
returns text 
as $function$
-- checks if the the table fields have the same details in the database as in the definition: 
-- data_type, not_null, check_constraint, default_constraint
-- select * from "bdd_table.migrate_details"('test1')
declare
    v_row record;
    v_sql text;
    v_sql_field text;
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

    FOR v_row IN
        select f.table_name, f.field_name, f.data_type
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.data_type_formatted != f.bdc_data_type_formatted
    LOOP
        v_sql_field = format(E'alter table %I alter column %I type %s;',i_table_name, v_row.field_name, v_row.data_type);
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.not_null
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.not_null_formatted != f.bdc_is_nullable_formatted
    LOOP
        if v_row.not_null = '' THEN
            v_sql_field = format(E'alter table %I alter column %I drop not null;',i_table_name, v_row.field_name);
        ELSE
            v_sql_field = format(E'alter table %I alter column %I set not null;',i_table_name, v_row.field_name);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.default_constraint
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.default_constraint_formatted != f.bdc_column_default_formatted
    LOOP
        if v_row.default_constraint = '' then
            v_sql_field = format(E'alter table %I alter column %I drop default;',i_table_name, v_row.field_name);
        else
            v_sql_field = format(E'alter table %I alter column %I set %s;',i_table_name, v_row.field_name, v_row.default_constraint);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;

    FOR v_row IN
        select f.table_name, f.field_name, f.check_constraint, f.check_constraint_name
        from "bdd_field_table.details" f
        where f.table_name= i_table_name and 
        f.check_constraint_formatted != f.bdc_check_clause_formatted
    LOOP
        if v_row.check_constraint = '' then
            v_sql_field = format(E'alter table %I alter column %I drop constraint %s;',i_table_name, v_row.field_name, v_row.check_constraint_name);
        else
            v_sql_field = format(E'alter table %I add %s;',i_table_name, v_row.check_constraint);
        end if;
        v_sql = format (E'%s\n%s',v_sql, v_sql_field);
        -- printing before execute will show where eas the error
        raise debug '%', v_sql_field;
        -- execute v_sql_field;
    END LOOP;
    return format(E'executed sql code:\n%s', v_sql);
end;
$function$ language plpgsql;

$source_code$);
