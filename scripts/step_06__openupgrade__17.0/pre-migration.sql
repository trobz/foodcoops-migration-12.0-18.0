-- Update product_template uom_id to match stock_move_line product_uom_id
-- default uom_id is 1 (Units)
-- UPDATE product_template pt
-- SET uom_id = sml.product_uom_id
-- FROM product_product pp
-- JOIN stock_move_line sml ON pp.id = sml.product_id
-- WHERE pt.id = pp.product_tmpl_id
--   AND pt.uom_id != sml.product_uom_id;

-- update catgory of Units to Weight
UPDATE uom_uom
SET category_id = (SELECT id FROM uom_category WHERE name->>'en_US' = 'Weight')
WHERE name->>'en_US' = 'Units';