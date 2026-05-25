
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
    -- sqq
    -- -------------------------------------------------------------------------
    ELSIF db_prefix = 'sqq' THEN

        UPDATE ir_model_data
        SET noupdate = 't'
        WHERE name='product_category_Souscriptions' and model='product.category';

    -- -------------------------------------------------------------------------
    -- No match
    -- -------------------------------------------------------------------------
    ELSE
        RAISE NOTICE 'No specific pre-migration SQL for prefix: %', db_prefix;

    END IF;

END $$;