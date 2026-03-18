

UPDATE ir_cron SET active = FALSE;
DELETE FROM ir_mail_server;
DELETE FROM fetchmail_server;
DELETE FROM ir_attachment WHERE url LIKE '/web/content/%';
DELETE FROM queue_job;

UPDATE ir_config_parameter SET key = 'mail.bounce.alias.12.0'
WHERE key = 'mail.bounce.alias';

DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- tmt
    -- -------------------------------------------------------------------------
    IF db_prefix = 'tmt' THEN

        -- Remove orphaned ir_model_data entries for muk_* modules merged into dms
        -- in Odoo 13 (OpenUpgrade apriori). Production db had both module_muk_security
        -- (orphaned, no ir_module_module row) AND module_dms already registered, causing:
        -- "duplicate key value violates unique constraint ir_model_data_module_name_uniq_index"
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
          )
          AND EXISTS (
              SELECT 1 FROM ir_model_data d2
              WHERE d2.module = 'base'
                AND d2.model = 'ir.module.module'
                AND d2.name = 'module_dms'
          );

    END IF;

END $$;

