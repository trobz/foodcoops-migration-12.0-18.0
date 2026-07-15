-- Force-install the coop_shift_website_event bridge module during the final
-- 18.0 regular update when both of its dependencies are already installed.
-- This keeps the compatibility patch active on migrated databases even when
-- auto_install does not get reevaluated as expected during the upgrade flow.
UPDATE ir_module_module AS bridge
SET state = 'installed'
WHERE bridge.name = 'coop_shift_website_event'
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'coop_shift'
        AND dep.state = 'installed'
  )
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'website_event'
        AND dep.state = 'installed'
  );

-- Force-install # coop_stock_repair only if its base dependency is present.
UPDATE ir_module_module AS bridge
SET state = 'installed'
WHERE bridge.name = 'coop_stock_repair'
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'repair'
        AND dep.state = 'installed'
  );

-- Force-install # website_coop_custom only if its base dependency is present.
UPDATE ir_module_module AS bridge
SET state = 'installed'
WHERE bridge.name = 'website_coop_custom'
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'website_sale'
        AND dep.state = 'installed'
  );

-- Force-install # pos_data_role only when both dependencies are installed.
UPDATE ir_module_module AS bridge
SET state = 'installed'
WHERE bridge.name = 'pos_data_role'
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'foodcoop_data_role'
        AND dep.state = 'installed'
  )
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'pos_automatic_cashdrawer_cashlogy'
        AND dep.state = 'installed'
  );

-- Force-install # edi_purchase_diapar_oca if edi_purchase_diapar is installed.
UPDATE ir_module_module AS bridge
SET state = 'installed'
WHERE bridge.name = 'edi_purchase_diapar_oca'
  AND EXISTS (
      SELECT 1
      FROM ir_module_module AS dep
      WHERE dep.name = 'edi_purchase_diapar'
        AND dep.state = 'installed'
  );

