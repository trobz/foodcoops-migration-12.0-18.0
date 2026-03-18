

UPDATE ir_cron SET active = FALSE;
DELETE FROM ir_mail_server;
DELETE FROM fetchmail_server;
DELETE FROM ir_attachment WHERE url LIKE '/web/content/%';
DELETE FROM queue_job;

UPDATE ir_config_parameter SET key = 'mail.bounce.alias.12.0'
WHERE key = 'mail.bounce.alias';


-- Dispatcher: run database-specific SQL based on current database name prefix.
DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- superquinquin
    -- -------------------------------------------------------------------------
    IF db_prefix = 'tmt' THEN

        -- Why staging (Feb 26) worked but production (Mar 11) failed
        -- From the staging log, ALL muk queries returned 0 rows — neither muk_security nor dms was registered in the Feb 26 database.

        -- The March 11 production database has both module_muk_security (orphaned — no corresponding ir_module_module row) and module_dms present. This means:

        -- dms was registered/installed on the production 12.0 system between Feb 26–Mar 11
        -- muk_security was previously installed/registered then partially removed (leaving an orphaned ir_model_data record)
        -- Fix
        -- Add to scripts/step_02__openupgrade__13.0/pre-migration.sql before OpenUpgrade runs:


        -- Remove orphaned ir_model_data entries for muk_* modules where:
        -- 1. The module is no longer in ir_module_module (orphaned)
        -- 2. The target 'dms' module already exists in ir_model_data
        -- This prevents OpenUpgrade's muk_security->dms merge from hitting a unique constraint
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
        -- This safely removes orphaned module_muk_* entries from ir_model_data only when:

        -- The corresponding module is NOT in ir_module_module (truly orphaned)
        -- module_dms already exists (causing the conflict)
    -- -------------------------------------------------------------------------
    -- No match
    -- -------------------------------------------------------------------------
    ELSE
        RAISE NOTICE 'No specific pre-migration SQL for prefix: %', db_prefix;

    END IF;

END $$;

