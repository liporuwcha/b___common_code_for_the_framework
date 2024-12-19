select bdc_function_migrate('bdd_table.migrate',
$source_code$

create function "bdd_table.migrate"(i_table_name name)
returns text 
as
-- checks if the table has all the fields
-- if needed it adds the fields 
-- select * from "bdd_table.migrate"('bdd_unit')
$$
declare
    v_row record;
    v_sql text;
    v_sql_fields text;
    v_void text;
begin

    -- if table not exists, create it with all fields in one go.
    if not exists(select * from bdc_table_list a where a.table_name=i_table_name) then
        --prepare fields
        FOR v_row IN
            select f.field_name, f.data_type, f.not_null, f.default_constraint, f.check_constraint
            from bdd_field_table f
            where f.jid_bdd_table in (select id_bdd_table from bdd_table t where t.table_name = i_table_name)
        LOOP
            if v_sql_fields != '' then
                v_sql_fields = format(E'%s ,\n', v_sql_fields);
            end if;
            v_sql_fields = format('%s %s %s %s %s %s', v_sql_fields, v_row.field_name, v_row.data_type, v_row.not_null, v_row.default_constraint, v_row.check_constraint);

        END LOOP;

        v_sql = format(E'create table %s (\n%s\n)', i_table_name, v_sql_fields);
        execute v_sql;

        return format('sql code: %s', v_sql);
    else
        -- table exists, what fields don't exist?
        
    end if;

return format('End function: %I', i_table_name);
end;
$$ language plpgsql;

$source_code$);
