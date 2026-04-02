ALTER TABLE product_supplierinfo RENAME COLUMN package_qty TO mig_package_qty;
-- ALTER TABLE account_move_line RENAME COLUMN package_qty TO mig_package_qty;
ALTER TABLE purchase_order_line RENAME COLUMN package_qty TO mig_package_qty;
-- ALTER TABLE stock_move RENAME COLUMN package_qty TO mig_package_qty;

-- Update qty of product_packaging if it is 0 to 1 to avoid division by zero in the migration script.
-- Lalouve product: [0391110] PAPIER OD BLANC A4 5RAMx500F
UPDATE product_packaging SET qty = 1 WHERE qty = 0;