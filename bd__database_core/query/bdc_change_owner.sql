-- change owner
-- all objects must have the same owner lip_migration_user

select format('alter function "%s" owner to lip_migration_user;',object_name) as sql_code
from "bdc_object_owner" where object_owner != 'lip_migration_user'
