ALTER TABLE product_supplierinfo RENAME COLUMN package_qty TO mig_package_qty;
-- ALTER TABLE account_move_line RENAME COLUMN package_qty TO mig_package_qty;
ALTER TABLE purchase_order_line RENAME COLUMN package_qty TO mig_package_qty;
-- ALTER TABLE stock_move RENAME COLUMN package_qty TO mig_package_qty;
