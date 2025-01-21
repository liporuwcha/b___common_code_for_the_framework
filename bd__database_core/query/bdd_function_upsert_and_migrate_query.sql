-- First create the function in your sql editor
-- when it works, copy the definition between the delimiters $sc$
-- and then select all `ctrl+a` and run query `ctrl+enter`
-- that will insert/update the function definition into bdd_function
-- Then use Undo ctrl+z to return this query as it was before paste.

select "bdd_function.upsert_and_migrate"(
$sc$



$sc$);
