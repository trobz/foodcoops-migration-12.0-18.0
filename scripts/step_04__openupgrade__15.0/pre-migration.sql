-- Dispatcher: run database-specific SQL based on current database name prefix.

DO $$
DECLARE
    db_prefix TEXT := split_part(current_database(), '_', 1);
BEGIN

    -- -------------------------------------------------------------------------
    -- superquinquin
    -- -------------------------------------------------------------------------
    IF db_prefix = 'superquinquin' THEN

        -- fix duplicate barcode in product_packaging
        -- alter table product_packaging to add new field old_barcode
        -- for duplicate barcode record, copy original barcode to old barcode,
        -- rename current duplicate barcode with suffix _1....n

        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'product_packaging' AND column_name = 'old_barcode'
        ) THEN
            ALTER TABLE product_packaging ADD COLUMN old_barcode VARCHAR;
        END IF;

        WITH duplicates AS (
            SELECT id,
                   barcode,
                   ROW_NUMBER() OVER (PARTITION BY barcode ORDER BY id) AS rn
            FROM product_packaging
            WHERE barcode IS NOT NULL
        )
        UPDATE product_packaging pp
        SET old_barcode = d.barcode,
            barcode     = d.barcode || '_' || (d.rn - 1)
        FROM duplicates d
        WHERE pp.id = d.id
          AND d.rn > 1;

    ELSIF db_prefix = 'tmt' THEN

        -- # OCA/account-financial-tools
        -- found error when doing rename module "account_menu" to "account_usability",
        UPDATE ir_module_module SET name = 'account_usability_new' WHERE name = 'account_usability';
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
