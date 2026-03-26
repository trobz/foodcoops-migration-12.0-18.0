
-- UPDATE product_template SET weight_uom_id = (
--     SELECT res_id FROM ir_model_data
--     WHERE model='uom.uom' AND name='product_uom_kgm' AND module='uom'
-- ) WHERE weight_uom_id ISNULL;
