
-- printnode_base is a 12.0-only module and is skipped in 18.0.
-- Relax legacy NOT NULL constraints on its orphaned tables so the remaining
-- data can survive the final regular upgrade without schema enforcement from
-- the removed module.
DO $$
DECLARE
    legacy_column RECORD;
BEGIN
    FOR legacy_column IN
        WITH legacy_models AS (
            SELECT REPLACE(model, '.', '_') AS table_name
            FROM ir_model
            WHERE model LIKE 'printnode.%'
               OR model IN ('shipping.label', 'shipping.label.document')
        )
        SELECT cols.table_name, cols.column_name
        FROM information_schema.columns AS cols
        JOIN legacy_models AS models
            ON models.table_name = cols.table_name
        WHERE cols.table_schema = 'public'
          AND cols.is_nullable = 'NO'
          AND cols.column_name NOT IN (
              'id',
              'create_uid',
              'create_date',
              'write_uid',
              'write_date'
          )
    LOOP
        EXECUTE format(
            'ALTER TABLE %I ALTER COLUMN %I DROP NOT NULL',
            legacy_column.table_name,
            legacy_column.column_name
        );
    END LOOP;
END $$;

-- Dispatcher: run database-specific SQL based on current database name prefix.
DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
    db_prefix_2 TEXT := concat_ws('_', split_part(current_database(), '_', 1), split_part(current_database(), '_', 2));
BEGIN

    -- -------------------------------------------------------------------------
    -- sqq_vdm
    -- -------------------------------------------------------------------------
    IF db_prefix_2 = 'sqq_vdm' THEN
        UPDATE ir_ui_view
        SET active = false
        WHERE key = 'website_sale.products'
            AND id IN (
                    SELECT v.id
                    FROM ir_ui_view v
                    LEFT JOIN ir_model_data imd
                            ON imd.model = 'ir.ui.view'
                            AND imd.res_id = v.id
                    WHERE v.key = 'website_sale.products'
                        AND imd.id IS NULL
            );

        WITH RECURSIVE orphan_website_sale_product_views AS (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key = 'website_sale.product'
              AND imd.id IS NULL
        ), website_sale_product_view_descendants AS (
            SELECT id
            FROM orphan_website_sale_product_views

            UNION

            SELECT child.id
            FROM ir_ui_view child
            JOIN website_sale_product_view_descendants parent
                ON child.inherit_id = parent.id
        )
        UPDATE ir_ui_view
        SET active = false
        WHERE id IN (SELECT id FROM website_sale_product_view_descendants);

        -- Keep the canonical portal.frontend_layout view that is linked to
        -- ir_model_data and remove any duplicate orphaned database view.
        UPDATE ir_ui_view
        SET inherit_id = canonical.id
        FROM (
            SELECT v.id
            FROM ir_ui_view v
            JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key = 'portal.frontend_layout'
        ) AS canonical
        WHERE inherit_id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key = 'portal.frontend_layout'
              AND imd.id IS NULL
        );

        DELETE FROM ir_ui_view_custom
        WHERE ref_id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key = 'portal.frontend_layout'
              AND imd.id IS NULL
        );

        DELETE FROM ir_ui_view
        WHERE id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key = 'portal.frontend_layout'
              AND imd.id IS NULL
        );

    -- -------------------------------------------------------------------------
    -- lacoopsurmer
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'lacoopsurmer' THEN

        -- Keep the canonical portal views that are linked to ir_model_data and
        -- remove any duplicate orphaned database views.
        UPDATE ir_ui_view
        SET inherit_id = canonical.id
        FROM (
            SELECT v.id
            FROM ir_ui_view v
            JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key IN (
                'payment.portal_my_home_payment',
                'account.portal_my_home_invoice',
                'project.portal_my_home'
            )
        ) AS canonical
        WHERE inherit_id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key IN (
                'payment.portal_my_home_payment',
                'account.portal_my_home_invoice',
                'project.portal_my_home'
            )
              AND imd.id IS NULL
        );

        DELETE FROM ir_ui_view_custom
        WHERE ref_id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key IN (
                'payment.portal_my_home_payment',
                'account.portal_my_home_invoice',
                'project.portal_my_home'
            )
              AND imd.id IS NULL
        );

        DELETE FROM ir_ui_view
        WHERE id IN (
            SELECT v.id
            FROM ir_ui_view v
            LEFT JOIN ir_model_data imd
                ON imd.model = 'ir.ui.view'
               AND imd.res_id = v.id
            WHERE v.key IN (
                'payment.portal_my_home_payment',
                'account.portal_my_home_invoice',
                'project.portal_my_home'
            )
              AND imd.id IS NULL
        );

    -- -------------------------------------------------------------------------
    -- sqq
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'sqq' THEN

        UPDATE ir_model_data
        SET noupdate = 't'
        WHERE name='product_category_Souscriptions' and model='product.category';

        UPDATE website
        SET ecommerce_access = 'logged_in';

    -- -------------------------------------------------------------------------
    -- No match
    -- -------------------------------------------------------------------------
    ELSE
        RAISE NOTICE 'No specific pre-migration SQL for prefix: %', db_prefix;

    END IF;

END $$;


-- Set the new modules to be installed, so they can be upgraded during the migration
UPDATE ir_module_module
SET state = 'installed'
WHERE name IN (
    'pos_order_remove_line',
    'spreadsheet_dashboard', -- depends on coop_membershift
    'web_chatter_position',
    'coop_web',
    'coop_pos_access',
    'coop_pos_return',
    'coop_pos_search'
);
