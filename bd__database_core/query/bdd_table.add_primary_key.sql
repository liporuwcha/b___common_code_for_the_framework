

ALTER TABLE bdd_domain
ADD PRIMARY KEY (id_bdd_domain);

new field is_primary_key boolean


CREATE UNIQUE INDEX CONCURRENTLY uq_bdd_domain_id_bdd_domain
ON bdd_domain (id_bdd_domain);

ALTER TABLE bdd_domain
ADD CONSTRAINT uq_bdd_domain_id_bdd_domain
UNIQUE USING INDEX uq_bdd_domain_id_bdd_domain;


