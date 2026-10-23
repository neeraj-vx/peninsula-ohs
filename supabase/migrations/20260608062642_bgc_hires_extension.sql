ALTER TABLE hires
  ADD COLUMN bgc_package_id  uuid    REFERENCES bgc_packages(id) ON DELETE SET NULL,
  ADD COLUMN bgc_required     boolean NOT NULL DEFAULT false,
  ADD COLUMN bgc_status       text;

CREATE INDEX idx_hires_bgc_pkg ON hires(bgc_package_id) WHERE bgc_package_id IS NOT NULL;
