

UPDATE ir_cron SET active = FALSE;

-- Mark UoM data as noupdate to prevent Odoo from re-applying uom_data.xml during migration.
-- Databases where a UoM category has no reference unit will fail with
-- _check_category_reference_uniqueness when Odoo loads a 'bigger'/'smaller' unit for that category.
UPDATE ir_model_data
SET noupdate = true
WHERE module = 'uom'
  AND model IN ('uom.uom', 'uom.category');
DELETE FROM ir_mail_server;
DELETE FROM fetchmail_server;
DELETE FROM ir_attachment WHERE url LIKE '/web/content/%';
DELETE FROM queue_job;

UPDATE ir_config_parameter SET key = 'mail.bounce.alias.12.0'
WHERE key = 'mail.bounce.alias';

-- Remove orphaned ir_model_data entries for muk_* modules that OpenUpgrade merges into
-- dms in 13.0. When multiple muk_* entries are orphaned (present in ir_model_data but
-- absent from ir_module_module), OpenUpgrade renames the first one to module_dms then
-- fails renaming the rest with a duplicate key violation on ir_model_data_module_name_uniq_index.
DELETE FROM ir_model_data
WHERE module = 'base'
    AND model = 'ir.module.module'
    AND name IN (
        'module_muk_security',
        'module_muk_attachment_lobject',
        'module_muk_autovacuum',
        'module_muk_utils',
        'module_muk_web_utils',
        'module_muk_dms',
        'module_muk_dms_access',
        'module_muk_dms_actions',
        'module_muk_dms_attachment',
        'module_muk_dms_field',
        'module_muk_dms_file',
        'module_muk_dms_lobject',
        'module_muk_dms_mail',
        'module_muk_dms_thumbnails',
        'module_muk_dms_view'
    )
    AND NOT EXISTS (
        SELECT 1 FROM ir_module_module
        WHERE name = REPLACE(ir_model_data.name, 'module_', '')
    );
