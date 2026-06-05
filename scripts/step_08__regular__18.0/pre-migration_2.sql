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