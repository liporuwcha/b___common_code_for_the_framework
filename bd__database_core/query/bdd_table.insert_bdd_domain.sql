INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    5,
    'bdd_domain'
  );

INSERT INTO bdd_field_table (
    id_bdd_field_table,
    jid_bdd_table,
    field_name,
    data_type,
not_null,
default_constraint,
check_constraint
  )
VALUES 
( 13, 5, 'id_bdd_domain', 'integer', 'not null', '', 'check (value > 0)'),
( 14, 5, 'domain_name','name','not null', '', 'check (length(value) > 0)'),
( 15, 5, 'notes','text','not null', 'default''''', '')
( 16, 5, 'source_code', 'text', 'not null', '','')
;