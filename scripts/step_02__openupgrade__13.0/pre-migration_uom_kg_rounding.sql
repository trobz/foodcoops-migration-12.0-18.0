-- Preserve the original rounding precision of the kilogram UoM so it can be
-- restored after the final 18.0 regular update.
DELETE FROM ir_config_parameter
WHERE key = 'migration.uom.product_uom_kgm.rounding';

INSERT INTO ir_config_parameter (key, value, create_uid, create_date, write_uid, write_date)
SELECT
    'migration.uom.product_uom_kgm.rounding',
    uu.rounding::text,
    1,
    NOW(),
    1,
    NOW()
FROM uom_uom AS uu
JOIN ir_model_data AS imd
    ON imd.model = 'uom.uom'
   AND imd.res_id = uu.id
WHERE imd.module = 'uom'
  AND imd.name = 'product_uom_kgm';