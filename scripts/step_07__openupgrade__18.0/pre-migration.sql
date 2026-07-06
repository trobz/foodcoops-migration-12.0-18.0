
update ir_model_data
set noupdate='t'
where name in ('location_inventory', 'stock_location_scrapped') and module='stock';

-- Create missing ir_model_data entry for the ir.actions.server that is delegated from
-- stock.ir_cron_scheduler_action. The entry (stock.ir_cron_scheduler_action_ir_actions_server)
-- is only auto-created on record CREATE, never on UPDATE, so databases migrated through
-- earlier versions never received it. The 18.0 stock_rule_views.xml and mrp module both
-- reference it in menu items, causing a ParseError if the entry is absent.
INSERT INTO ir_model_data (name, module, model, res_id, noupdate, date_init, date_update)
SELECT
    'ir_cron_scheduler_action_ir_actions_server',
    'stock',
    'ir.actions.server',
    ic.ir_actions_server_id,
    false,
    NOW(),
    NOW()
FROM ir_model_data imd
JOIN ir_cron ic ON ic.id = imd.res_id
WHERE imd.module = 'stock'
  AND imd.name = 'ir_cron_scheduler_action'
  AND imd.model = 'ir.cron'
  AND ic.ir_actions_server_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM ir_model_data
      WHERE module = 'stock'
        AND name = 'ir_cron_scheduler_action_ir_actions_server'
  );

-- drop array_concat_agg in postgres12, to migrate to postgres14+
-- # Since Postgres 14, the argument to array_cat must be
-- # anycompatiblearray instead of anyarray. See
-- # <https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.13.4>.
-- # We detect the version and use the correct type as needed.
DROP AGGREGATE IF EXISTS array_concat_agg(anyarray);

-- copy camptocamp upgrade tools: https://github.com/camptocamp/odoo-upgrade-tools/blob/main/odoo_upgrade_tools/odoo/%7B%7Bcookiecutter.odoo_dir%7D%7D/songs/migration_db/songs/generic/prepare_views_for_upgrade.sql
DO $$
    BEGIN
        IF NOT EXISTS (
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name='ir_ui_view' and column_name='active_backup'
        ) THEN
            ALTER TABLE ir_ui_view ADD COLUMN active_backup BOOLEAN;
            -- Set the right 'active_backup' value for modules already migrated
            UPDATE ir_ui_view SET active_backup=active
            WHERE id IN (
                SELECT res_id FROM ir_model_data
                WHERE model = 'ir.ui.view'
                AND module IN (
                    SELECT name FROM ir_module_module
                    WHERE state = 'installed'
                )
            );
            -- Set 'true' by default in 'active_backup' for all other modules
            UPDATE ir_ui_view SET active_backup=true
            WHERE id NOT IN (
                SELECT res_id FROM ir_model_data
                WHERE model = 'ir.ui.view'
                AND module IN (
                    SELECT name FROM ir_module_module
                    WHERE state = 'installed'
                )
            );
            RAISE WARNING E'"ir_ui_view.active_backup" column has been automatically created, but consider installing "camptocamp_migration_tools" addon on the production database to get it filled with right values';
        END IF;
    END;
$$;
-- Disable all views excepting standard ones already migrated by Odoo SA.
-- Therefore, views from 'base' addon have to be enable as first inheriting
-- views are based on them.
-- UPDATE ir_ui_view SET active=false
-- WHERE id NOT IN (
--     SELECT res_id
--     FROM ir_model_data
--     WHERE model='ir.ui.view'
--     AND module IN (
--         SELECT name FROM ir_module_module WHERE state='installed'
--     )
-- );

-- UPDATE ir_ui_menu SET active=false
-- WHERE id NOT IN (
--     SELECT res_id
--     FROM ir_model_data
--     WHERE model='ir.ui.menu'
--     AND module IN (
--         SELECT name FROM ir_module_module WHERE state='installed'
--     )
-- );

-- disable specific modules
UPDATE ir_ui_view SET active=false
WHERE id IN (
    SELECT res_id
    FROM ir_model_data
    WHERE model='ir.ui.view' AND module IN ('l10n_fr_fec', 'dummy')
);

-- deleted un-migrated menu
-- UPDATE ir_ui_menu set active=false
-- WHERE id IN (
--     SELECT res_id
--     FROM ir_model_data
--     WHERE model='ir.ui.menu' AND module IN ('coop_purchase', 'dummy')
-- );


-- -- coop_purchase.action_invoice_refund
-- delete ir_action_act_window where id in (
--     SELECT res_id
--     FROM ir_model_data
--     WHERE model='ir.action.act_window' AND module='coop_purchase' and name='action_invoice_refund'
-- );

-- Clean config_parameter on coop_print_badge to recompute new default value
DELETE FROM ir_config_parameter WHERE key = 'reprint_change_field_ids';

-- Dispatcher: run database-specific SQL based on current database name prefix.
DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- superquinquin
    -- -------------------------------------------------------------------------
    IF db_prefix = 'superquinquin' THEN

        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_name = 'printnode_scenario'
        ) THEN
            -- Remove scenarios whose referenced report will be deleted by OpenUpgrade
            
            -- DELETE FROM printnode_scenario
            -- WHERE report_id IS NOT NULL
            --   AND report_id NOT IN (SELECT id FROM ir_act_report_xml);
            -- Drop NOT NULL so remaining ON DELETE SET NULL can succeed
            
            ALTER TABLE printnode_scenario ALTER COLUMN report_id DROP NOT NULL;
        END IF;

    -- -------------------------------------------------------------------------
    -- tmt
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'tmt' THEN

        -- Duplicate res_groups sharing the same (category_id, en_US name) as a
        -- canonical sale module group cause a unique constraint violation on
        -- res_groups_name_uniq when Odoo merges fr_FR translations in 18.0.
        -- The duplicate may or may not have its own ir_model_data entry.
        --
        -- Strategy: keep only the sale-module canonical group for each
        -- (category_id, en_US name) bucket; delete everything else in that bucket.
        -- ON DELETE CASCADE on the rel tables handles group memberships automatically.
        WITH sale_groups AS (
            SELECT g.id, g.category_id, g.name->>'en_US' AS name_en
            FROM res_groups g
            JOIN ir_model_data imd ON imd.model = 'res.groups'
                AND imd.module = 'sale'
                AND imd.res_id = g.id
            WHERE g.name->>'en_US' IS NOT NULL
        )
        DELETE FROM res_groups
        WHERE id IN (
            SELECT g.id
            FROM res_groups g
            JOIN sale_groups sg
                ON sg.category_id = g.category_id
               AND (g.name->>'en_US') = sg.name_en
            WHERE g.id <> sg.id
              AND g.id NOT IN (SELECT id FROM sale_groups)
        );
    -- -------------------------------------------------------------------------
    -- otsokop
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'otsokop' THEN
        UPDATE ir_cron
        SET active = true
        WHERE id = (SELECT res_id from ir_model_data where module='stock' and model='ir.cron' and name='ir_cron_scheduler_action');


    -- -------------------------------------------------------------------------
    -- lalouve
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'lalouve' THEN

        -- Add lalouve-specific pre-migration SQL here
        RAISE NOTICE 'Running lalouve pre-migration for database: %', current_database();

    -- -------------------------------------------------------------------------
    -- No match
    -- -------------------------------------------------------------------------
    ELSE
        RAISE NOTICE 'No specific pre-migration SQL for prefix: %', db_prefix;

    END IF;

END $$;
