import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_0_stock_operation_type.py script ...")

env = env  # noqa: F821

# Fix Operation Types: Receipt records should have Source Location, Delivery records should have Destination Location

# Get reference locations
supplier_location = env.ref('stock.stock_location_suppliers', raise_if_not_found=False)
customer_location = env.ref('stock.stock_location_customers', raise_if_not_found=False)

if not supplier_location or not customer_location:
    _logger.error("Could not find required stock locations (suppliers or customers)")
else:
    # Fix Receipt operation types (incoming): set default source location to Suppliers
    receipt_types = env['stock.picking.type'].sudo().search([
        ('code', '=', 'incoming'),
        ('default_location_src_id', '=', False)
    ])
    if receipt_types:
        _logger.info("Updating %d Receipt operation types to set Source Location to Suppliers", len(receipt_types))
        receipt_types.write({'default_location_src_id': supplier_location.id})
    else:
        _logger.info("No Receipt operation types found without Source Location")

    # Fix Delivery operation types (outgoing): set default destination location to Customers
    delivery_types = env['stock.picking.type'].sudo().search([
        ('code', '=', 'outgoing'),
        ('default_location_dest_id', '=', False)
    ])
    if delivery_types:
        _logger.info("Updating %d Delivery operation types to set Destination Location to Customers", len(delivery_types))
        delivery_types.write({'default_location_dest_id': customer_location.id})
    else:
        _logger.info("No Delivery operation types found without Destination Location")

env.cr.commit()
_logger.info("Finished post-migration_2_0_stock_operation_type.py script")
