-- already handled in migration OCA 13.0/point_of_sale/migration/13.0.1.0.1/end-migration.py
-- delete from ir_model_data where model='stock.picking.type' and res_id=6; #pos order picking type

-- x_location is a Studio-created Selection field on calendar.event.
-- The value 'tmt' is not valid in 14.0 and causes ValueError in
-- calendar/14.0.1.0/post-migration.py create_recurrent_events when
-- _apply_recurrence copies event values to recreate recurrent events.
UPDATE calendar_event SET x_location = NULL WHERE x_location = 'tmt';

-- Mark UoM data as noupdate to prevent Odoo from re-applying uom_data.xml during migration.
-- Databases where a UoM category has no reference unit will fail with
-- _check_category_reference_uniqueness when Odoo loads a 'bigger'/'smaller' unit for that category.
-- set no update = true to create missing uom data if possible
UPDATE ir_model_data
SET noupdate = true
WHERE module = 'uom'
  AND model = 'uom.uom';