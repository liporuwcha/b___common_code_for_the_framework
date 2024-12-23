
-- random for id
do $anonymous_PLpgSQL_block$
declare v_r integer;
begin
  select bdc_random_int() into v_r;
  raise notice 'my random: %', v_r;
end;$anonymous_PLpgSQL_block$;

INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    4,
    'bdd_unit'
  );

INSERT INTO bdd_field_table (
    id_bdd_field_table,
    jid_bdd_table,
    field_name,
    data_type
  )
VALUES 
( 10, 4, 'id_bdd_unit', 'integer' ),
( 11, 4, 'unit_name','name'),
( 12, 4, 'notes','text')
;
