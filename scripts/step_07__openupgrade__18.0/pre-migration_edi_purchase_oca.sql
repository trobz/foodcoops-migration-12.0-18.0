-- Recreate missing XML ID for default EDI Purchase configuration data.

INSERT INTO ir_model_data (name, module, model, res_id, noupdate, date_init, date_update)
SELECT
    'edi_conf_trigger_purchase_order_state_change',
    'edi_purchase_oca',
    'edi.configuration.trigger',
    ect.id,
    false,
    NOW(),
    NOW()
FROM edi_configuration_trigger ect
WHERE ect.code = 'on_edi_purchase_order_state_change'
  AND NOT EXISTS (
      SELECT 1
      FROM ir_model_data imd
      WHERE imd.module = 'edi_purchase_oca'
        AND imd.name = 'edi_conf_trigger_purchase_order_state_change'
  );