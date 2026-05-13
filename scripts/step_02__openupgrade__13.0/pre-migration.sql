

UPDATE ir_cron SET active = FALSE;

-- Fix ir.translation records with invalid state value 'false' (string).
-- These were stored as the Python repr of False instead of a valid selection value.
UPDATE ir_translation SET state = 'to_translate' WHERE state = 'false';

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

-- Dispatcher: run database-specific SQL based on current database name prefix.
DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- sqq
    -- -------------------------------------------------------------------------
    IF db_prefix = 'sqq' THEN
        -- Deactivate custom views that target the obsolete //t[@t-set='head_website'] xpath.
        -- This t-set block was removed from website.layout before Odoo 18; keeping these views
        -- active causes a ParseError / registry failure when Odoo 18 loads the website module.
        -- Deactivating early (at 13.0) prevents them from being re-activated in later steps.
        UPDATE ir_ui_view SET active = false
        WHERE arch_db::text LIKE '%//t[@t-set=''head_website'']%'
        AND (
            -- No xml_id at all (truly custom, orphaned view)
            id NOT IN (SELECT res_id FROM ir_model_data WHERE model = 'ir.ui.view')
            OR
            -- Has an xml_id but from a module that is not currently installed
            id IN (
                SELECT res_id FROM ir_model_data
                WHERE model = 'ir.ui.view'
                    AND module NOT IN (SELECT name FROM ir_module_module WHERE state = 'installed')
            )
        );

        -- select name,id, active,arch_db from ir_ui_view where 
        -- arch_db::text LIKE '%//t[@t-set=''head_website'']%'
        --   AND (
        --       -- No xml_id at all (truly custom, orphaned view)
        --       id NOT IN (SELECT res_id FROM ir_model_data WHERE model = 'ir.ui.view')
        --     --   OR
        --     --   -- Has an xml_id but from a module that is not currently installed
        --     --   id IN (
        --     --       SELECT res_id FROM ir_model_data
        --     --       WHERE model = 'ir.ui.view'
        --     --         AND module NOT IN (SELECT name FROM ir_module_module WHERE state = 'installed')
        --     --   )
        --   );
    ELSE
        RAISE NOTICE 'No specific pre-migration SQL for prefix: %', db_prefix;

    END IF;

END $$;


-- Clean some modules
UPDATE ir_module_module
SET state = 'uninstalled'
WHERE name IN (
    'web_environment_ribbon'
);
