
INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    2,
    'bdd_table'
  );

INSERT INTO bdd_field_table (
    id_bdd_field_table,
    jid_bdd_table,
    field_name,
    data_type
  )
VALUES 
( 3, 2, 'id_bdd_table', 'integer' ),
( 4, 2, 'table_name', 'name' )
;
