
INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    3,
    'bdd_field_table'
  );

INSERT INTO bdd_field_table (
    id_bdd_field_table,
    jid_bdd_table,
    field_name,
    data_type
  )
VALUES 
( 5, 3, 'id_bdd_field_table', 'integer' ),
( 6, 3, 'jid_bdd_table','integer'),
( 7, 3, 'field_name','name'),
( 8, 3, 'data_type','varchar(100)'),
( 9, 3, 'not_null','varchar(10)')
;

default_constraint

check_constraint

select * from bdd_field_table
