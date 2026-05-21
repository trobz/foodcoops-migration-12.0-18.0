
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

-- Set migrated modules as a variable for reuse in queries
DO $$
DECLARE
    migrated_modules text[] := ARRAY[
        'account_asset_management_xlsx',
        'account_bank_statement_import_caisse_epargne',
        'account_bank_statement_reconcile_option',
        'account_invoice_refund_option',
        'account_partner_journal',
        'account_payment_select_account',
        'account_payment_term_restricted',
        'barcodes_generator_partner',
        'barcodes_generator_product',
        'mail_template_conditional_attachment',
        'mass_mailing_access',
        'product_average_consumption',
        'product_history',
        'product_history_for_cpo',
        'product_to_scale_bizerba',
        'purchase_compute_order',
        'purchase_compute_order_min_package',
        'purchase_package_qty',
        'res_partner_account_move_line',
        'stock_scrap_product_report',
        'product_analytic'
    ];
BEGIN

    -- Set module state to 'installed'
    UPDATE ir_module_module
    SET state = 'installed'
    WHERE name = ANY(migrated_modules);

    -- Activate views in migrated modules
    UPDATE ir_ui_view
    SET active = true
    WHERE id IN (
        SELECT res_id
        FROM ir_model_data
        WHERE model = 'ir.ui.view'
          AND module = ANY(migrated_modules)
    );

    -- Activate menus in migrated modules
    UPDATE ir_ui_menu
    SET active = true
    WHERE id IN (
        SELECT res_id
        FROM ir_model_data
        WHERE model = 'ir.ui.menu'
          AND module = ANY(migrated_modules)
    );

END $$;

-- Clean some un-migrated modules
UPDATE ir_module_module
SET state = 'uninstalled'
WHERE name IN (
    'account_asset_management_menu', 
    -- 'account_asset_management_xlsx',
    -- 'account_bank_statement_import_caisse_epargne',
    -- 'account_bank_statement_reconcile_option',
    'account_bank_statement_reconciliation_report',
    -- 'account_export',
    -- 'account_financial_report_custom',
    -- 'accounting_pdf_reports',
    -- 'account_invoice_merge',
    -- 'account_invoice_refund_option',
    -- 'account_mass_reconcile',
    -- 'account_partner_journal',
    'account_payment_confirm',
    -- 'account_payment_select_account',
    -- 'account_payment_term_restricted',
    -- 'account_product_fiscal_classification',
    -- 'account_reconcile_pos_payments',
    -- 'auth_signup_email',
    -- 'barcodes_generator_partner',
    -- 'barcodes_generator_product',
    -- 'capital_subscription',
    -- 'coop_account',
    -- 'coop_account_check_deposit',
    -- 'coop_account_product_fiscal_classification',
    -- 'coop_badge_reader',
    -- 'coop_capital_certificate',
    -- 'coop_default_pricetag',
    -- 'coop_delivery_category',
    -- 'coop_disable_product',
    -- 'coop_inventory',
    -- 'coop_inventory_recurrent',
    -- 'coop_mass_mailing_contact',
    -- 'coop_membership',
    -- 'coop_membership_extension_limit',
    -- 'coop_membership_forbidden',
    'coop_numerical_keyboard',
    -- 'coop_parental_leave',
    -- 'coop_point_of_sale',
    -- 'coop_print_badge',
    -- 'coop_produce',
    -- 'coop_product_coefficient',
    -- 'coop_project',
    -- 'coop_purchase',
    -- 'coop_shift',
    -- 'coop_shift_qualification',
    -- 'coop_shit_counter_balance',
    -- 'coop_stock',
    'custom_caravane',
    'document_sidebar',
    'edi_purchase_base',
    'edi_purchase_config',
    'edi_purchase_diapar',
    -- 'email_validation_check',
    'excel_import_export',
    'excel_import_export_demo',
    'field_image_preview',
    -- 'foodcoop_data_fr',
    -- 'foodcoop_data_role',
    'foodcoop_data_role_functional_admin',
    -- 'foodcoop_module',
    'invisible_menu_groups',
    -- 'l10n_fr_coop_default_pricetag',
    -- 'l10n_fr_fec_background',
    -- 'l10n_fr_fec_group_sale_purchase',
    -- 'lalouve_custom',
    -- 'lalouve_custom_timesheet',
    -- 'mail_template_conditional_attachment',
    -- 'mass_mailing_access',
    'mass_operation_abstract',
    -- 'partner_validate_email',
    -- 'pos_access_right',
    -- 'pos_automatic_cashdrawer',
    -- 'pos_automatic_validation',
    -- 'pos_customer_required',
    -- 'pos_empty_home',
    -- 'pos_gross_margin_xlsx',
    'pos_meal_voucher',
    -- 'pos_order_report',
    -- 'pos_order_return_scrap',
    'pos_order_wait_save',
    'pos_payment_change',
    -- 'pos_payment_credit',
    -- 'pos_payment_credit_member',
    -- 'pos_payment_terminal',
    -- 'pos_payment_terminal_return',
    -- 'pos_price_to_weight',
    -- 'pos_quick_logout',
    -- 'pos_receipt_attachment',
    -- 'pos_report_session_summary',
    'pos_restrict_scan',
    -- 'pos_scrap_order',
    'pos_search_improvement',
    -- 'pos_ticket_send_by_mail',
    -- 'pos_transfer_account',
    -- 'product_average_consumption',
    -- 'product_history',
    -- 'product_history_for_cpo',
    -- 'product_to_scale_bizerba',
    -- 'purchase_compute_order',
    -- 'purchase_compute_order_min_package',
    -- 'purchase_package_qty',
    'res_partner_account_move_line',  -- Drop
    'stock_inventory_barcode',
    'stock_inventory_barcode_custom',
    -- 'stock_inventory_valuation_report',
    'stock_scrap_origin',  -- Drop
    -- 'stock_scrap_product_report',
    'web_export_xlsx',  -- Drop
    'web_sheet_full_width',  -- Drop
    -- 'web_widget_image_webcam',
    -- 'web_widget_image_webcam_portrait',
    -- 'product_analytic'
);

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
UPDATE ir_ui_view SET active=false
WHERE id NOT IN (
    SELECT res_id
    FROM ir_model_data
    WHERE model='ir.ui.view'
    AND module IN (
        SELECT name FROM ir_module_module WHERE state='installed'
    )
);

UPDATE ir_ui_menu SET active=false
WHERE id NOT IN (
    SELECT res_id
    FROM ir_model_data
    WHERE model='ir.ui.menu'
    AND module IN (
        SELECT name FROM ir_module_module WHERE state='installed'
    )
);

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
