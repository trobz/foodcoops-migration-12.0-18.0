
-- Set the new modules to be installed
UPDATE ir_module_module
SET state = 'installed'
WHERE name IN (
    'bundle_lalouve'
)
