
INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    1,
    'bdc_source_code'
  );

INSERT INTO bdd_field_table (
    id_bdd_field_table,
    jid_bdd_table,
    field_name,
    data_type
  )
VALUES 
( 1, 1, 'object_name', 'name' ),
( 2, 1, 'source_code', 'text' )
;

alter table bdd_table
alter column notes set default ''