
-- Set the new modules to be installed
-- bundle name is derived dynamically from the current database name prefix
-- e.g. database "superquinquin_prod_20250305" → bundle "bundle_superquinquin"
UPDATE ir_module_module
SET state = 'installed'
WHERE name IN (
    'bundle_' || split_part(current_database(), '_', 1),
    'pos_order_remove_line',
    'spreadsheet_dashboard' -- depends on coop_membershift
)
