CREATE TABLE accounts (
  id bigserial PRIMARY KEY,
  name text
);

ALTER TABLE projects
  ADD COLUMN account_id bigint references accounts(id)
;
CREATE INDEX idx_projects_account_id ON projects(account_id);

ALTER TABLE species
  ADD COLUMN account_id bigint references accounts(id)
;
CREATE INDEX idx_species_account_id ON projects(account_id);
