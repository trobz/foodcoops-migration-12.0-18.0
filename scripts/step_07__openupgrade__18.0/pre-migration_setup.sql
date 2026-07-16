
-- Set the new modules to be installed
-- bundle name is derived dynamically from the current database name prefix
-- e.g. database "superquinquin_prod_20250305" → bundle "bundle_superquinquin"
-- Rename coop_shit_counter_balance
UPDATE ir_module_module
SET name = 'coop_shift_counter_balance'
WHERE name = 'coop_shit_counter_balance';

UPDATE ir_model_data
SET module = 'coop_shift_counter_balance'
WHERE module = 'coop_shit_counter_balance';

UPDATE ir_model_data
SET name = 'module_coop_shift_counter_balance'
WHERE name = 'module_coop_shit_counter_balance';

-- Rename partner_validate_email
UPDATE ir_module_module
SET name = 'partner_email_check'
WHERE name = 'partner_validate_email';

UPDATE ir_model_data
SET module = 'partner_email_check'
WHERE module = 'partner_validate_email';

UPDATE ir_model_data
SET name = 'module_partner_email_check'
WHERE name = 'module_partner_validate_email';

-- Rename pos_product_analytic
UPDATE ir_module_module
SET name = 'product_analytic_pos'
WHERE name = 'pos_product_analytic';

UPDATE ir_model_data
SET module = 'product_analytic_pos'
WHERE module = 'pos_product_analytic';

UPDATE ir_model_data
SET name = 'module_product_analytic_pos'
WHERE name = 'module_pos_product_analytic';

-- Rename pos_payment_change to pos_payment_change_account
UPDATE ir_module_module
SET name = 'pos_payment_change_account'
WHERE name = 'pos_payment_change';

UPDATE ir_model_data
SET module = 'pos_payment_change_account'
WHERE module = 'pos_payment_change';

UPDATE ir_model_data
SET name = 'module_pos_payment_change_account'
WHERE name = 'module_pos_payment_change';

-- Rename stock_scrap_origin to scrap_reason_mandatory
UPDATE ir_module_module
SET name = 'scrap_reason_mandatory'
WHERE name = 'stock_scrap_origin';

UPDATE ir_model_data
SET module = 'scrap_reason_mandatory'
WHERE module = 'stock_scrap_origin';

UPDATE ir_model_data
SET name = 'module_scrap_reason_mandatory'
WHERE name = 'module_stock_scrap_origin';

-- Rename pos_payment_credit to pos_payment_credit_amount
UPDATE ir_module_module
SET name = 'pos_payment_credit_amount'
WHERE name = 'pos_payment_credit';

UPDATE ir_model_data
SET module = 'pos_payment_credit_amount'
WHERE module = 'pos_payment_credit';

UPDATE ir_model_data
SET name = 'module_pos_payment_credit_amount'
WHERE name = 'module_pos_payment_credit';


-- Rename pos_automatic_cashdrawer to pos_automatic_cashdrawer_cashlogy
UPDATE ir_module_module
SET name = 'pos_automatic_cashdrawer_cashlogy'
WHERE name = 'pos_automatic_cashdrawer';

UPDATE ir_model_data
SET module = 'pos_automatic_cashdrawer_cashlogy'
WHERE module = 'pos_automatic_cashdrawer';

UPDATE ir_model_data
SET name = 'module_pos_automatic_cashdrawer_cashlogy'
WHERE name = 'module_pos_automatic_cashdrawer';

-- Rename pos_deposit to pos_container_deposit
UPDATE ir_module_module
SET name = 'pos_container_deposit'
WHERE name = 'pos_deposit';

UPDATE ir_model_data
SET module = 'pos_container_deposit'
WHERE module = 'pos_deposit';

UPDATE ir_model_data
SET name = 'module_pos_container_deposit'
WHERE name = 'module_pos_deposit';
