-- stock.inventory.line was removed in Odoo 15.0. During _process_end, Odoo tries to
-- unlink orphaned ir.model.fields records for this model via ORM, which fails with
-- KeyError because the model is no longer in the 15.0 registry. Delete via SQL first.
DELETE FROM ir_model_data
WHERE model = 'ir.model.fields'
  AND res_id IN (
      SELECT f.id FROM ir_model_fields f
      JOIN ir_model m ON f.model_id = m.id
      WHERE m.model = 'stock.inventory.line'
  );

DELETE FROM ir_model_fields
WHERE model_id IN (
    SELECT id FROM ir_model WHERE model = 'stock.inventory.line'
);

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

        -- account_menu is renamed to account_usability in 15.0 (OCA/account-financial-tools).
        -- The tmt db had both account_menu AND account_usability installed, so OpenUpgrade
        -- fails renaming module_account_menu → module_account_usability because the target
        -- already exists in ir_model_data.
        -- Fix: rename the existing account_usability out of the way in BOTH tables.
        UPDATE ir_module_module
        SET name = 'account_usability_old'
        WHERE name = 'account_usability';

        UPDATE ir_model_data
        SET name = 'module_account_usability_old'
        WHERE module = 'base'
          AND model = 'ir.module.module'
          AND name = 'module_account_usability';
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
