
INSERT INTO bdd_table (id_bdd_table, table_name)
VALUES (
    3,
    'bdd_field_table'
  );

INSERT INTO bdd_field_table ( id_bdd_field_table, jid_bdd_table, field_name, data_type )
VALUES 
( 5, 3, 'id_bdd_field_table', 'integer' ),
( 6, 3, 'jid_bdd_table','integer'),
( 7, 3, 'field_name','name'),
( 8, 3, 'data_type','varchar(100)'),
( 9, 3, 'not_null','varchar(10)')
;

INSERT INTO bdd_field_table ( id_bdd_field_table, jid_bdd_table, field_name, data_type, default_constraint, check_constraint )
VALUES ( bdc_random_int(), 3, 'is_primary_key', 'boolean','default false','' );



select "bdd_table.migrate"('bdd_field_table');
select "bdd_table.migrate_details"('bdd_field_table');

select * 
from bdd_field_table
-- update bdd_field_table set is_primary_key=true
where field_name like 'obj%'


