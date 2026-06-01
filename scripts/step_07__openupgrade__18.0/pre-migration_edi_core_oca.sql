-- Recreate missing XML IDs for default EDI configuration data after the
-- edi_oca -> edi_core_oca module rename.

WITH trigger_data(xmlid, code) AS (
    VALUES
        ('edi_conf_trigger_record_create', 'on_record_create'),
        ('edi_conf_trigger_record_write', 'on_record_write'),
        ('edi_config_trigger_record_done', 'on_edi_exchange_done'),
        ('edi_config_trigger_record_error', 'on_edi_exchange_error'),
        ('edi_conf_trigger_send_via_email', 'on_send_via_email'),
        ('edi_conf_trigger_send_via_edi', 'on_send_via_edi')
),
trigger_xmlids AS (
    SELECT
        td.xmlid,
        'edi.configuration.trigger' AS model,
        ect.id AS res_id
    FROM trigger_data td
    JOIN edi_configuration_trigger ect ON ect.code = td.code
),
config_data(xmlid, name, trigger_code) AS (
    VALUES
        ('edi_conf_send_via_email', 'Send Via Email', 'on_send_via_email'),
        ('edi_conf_send_via_edi', 'Send Via EDI', 'on_send_via_edi')
),
config_xmlids AS (
    SELECT
        cd.xmlid,
        'edi.configuration' AS model,
        ec.id AS res_id
    FROM config_data cd
    JOIN edi_configuration ec ON ec.name = cd.name
    JOIN edi_configuration_trigger ect ON ect.id = ec.trigger_id
    WHERE ect.code = cd.trigger_code
),
missing_xmlids AS (
    SELECT * FROM trigger_xmlids
    UNION ALL
    SELECT * FROM config_xmlids
)
INSERT INTO ir_model_data (name, module, model, res_id, noupdate, date_init, date_update)
SELECT
    mx.xmlid,
    'edi_core_oca',
    mx.model,
    mx.res_id,
    false,
    NOW(),
    NOW()
FROM missing_xmlids mx
WHERE NOT EXISTS (
    SELECT 1
    FROM ir_model_data imd
    WHERE imd.module = 'edi_core_oca'
      AND imd.name = mx.xmlid
);