UPDATE ir_model_data
SET noupdate='t'
WHERE module = 'point_of_sale'
    AND name = 'seq_picking_type_posout';