-- Update stock_move_line to uom_id to match product product_uom_id
-- default uom_id is 1 (Units)
-- #### SELECT to check

-- Automatically export mismatched UOM lines to a CSV file using psql meta-commands and SQL.
-- Note: This block runs the export and the update together, so mismatched lines are saved before fixing.

-- 1. Export lines with mismatched UOM and category
\echo 'Exporting mismatched stock_move_line UOMs to CSV before fixing...'
\set filename :CURRENT_DATE
\copy (
    SELECT
      sml.id AS move_id,
      pt.id AS template_id,
      pt_uom.name AS product_uom,
      sml_uom.name AS line_uom,
      pt_uom.category_id AS product_category,
      sml_uom.category_id AS line_category
    FROM stock_move_line AS sml
    JOIN product_product AS pp ON pp.id = sml.product_id
    JOIN product_template AS pt ON pt.id = pp.product_tmpl_id
    JOIN uom_uom AS pt_uom ON pt_uom.id = pt.uom_id
    JOIN uom_uom AS sml_uom ON sml_uom.id = sml.product_uom_id
    WHERE pt.uom_id <> sml.product_uom_id
      AND pt_uom.category_id <> sml_uom.category_id
) TO '/tmp/mismatch_stock_move_line_uom_export';

-- 2. Update lines to fix the UOM mismatch
-- The update statement remains below.
--  update stock_move_line to uom_id to match product product_uom_id
ALTER TABLE stock_move_line ADD COLUMN IF NOT EXISTS old_uom_id integer;

UPDATE stock_move_line AS sml
SET old_uom_id = sml.product_uom_id,
    product_uom_id = pt.uom_id
FROM product_product AS pp
JOIN product_template AS pt 
    ON pt.id = pp.product_tmpl_id
JOIN uom_uom AS pt_uom ON pt_uom.id = pt.uom_id,
     uom_uom AS sml_uom
WHERE sml.product_id = pp.id
  AND sml_uom.id = sml.product_uom_id
  AND pt.uom_id <> sml.product_uom_id
  AND pt_uom.category_id <> sml_uom.category_id;

-- 3. Export lines with mismatched UOM and category for sale_order_line
\echo 'Exporting mismatched sale_order_line UOMs to CSV before fixing...'
\copy (
    SELECT
      sol.id AS line_id,
      pt.id AS template_id,
      pt_uom.name AS product_uom,
      sol_uom.name AS line_uom,
      pt_uom.category_id AS product_category,
      sol_uom.category_id AS line_category
    FROM sale_order_line AS sol
    JOIN product_product AS pp ON pp.id = sol.product_id
    JOIN product_template AS pt ON pt.id = pp.product_tmpl_id
    JOIN uom_uom AS pt_uom ON pt_uom.id = pt.uom_id
    JOIN uom_uom AS sol_uom ON sol_uom.id = sol.product_uom
    WHERE pt.uom_id <> sol.product_uom
      AND pt_uom.category_id <> sol_uom.category_id
) TO '/tmp/mismatch_sale_order_line_uom_sol';

-- 4. Update lines to fix the UOM mismatch for sale_order_line
ALTER TABLE sale_order_line ADD COLUMN IF NOT EXISTS old_uom_id integer;

UPDATE sale_order_line AS sol
SET old_uom_id = sol.product_uom,
    product_uom = pt.uom_id
FROM product_product AS pp
JOIN product_template AS pt 
    ON pt.id = pp.product_tmpl_id
JOIN uom_uom AS pt_uom ON pt_uom.id = pt.uom_id,
     uom_uom AS sol_uom
WHERE sol.product_id = pp.id
  AND sol_uom.id = sol.product_uom
  AND pt.uom_id <> sol.product_uom
  AND pt_uom.category_id <> sol_uom.category_id;