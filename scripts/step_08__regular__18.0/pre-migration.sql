
-- Dispatcher: run database-specific SQL based on current database name prefix.
DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- sqq
    -- -------------------------------------------------------------------------
    IF db_prefix = 'sqq' THEN

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