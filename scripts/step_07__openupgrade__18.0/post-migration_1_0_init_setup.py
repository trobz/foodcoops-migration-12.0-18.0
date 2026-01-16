import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_0_init_setup.py script ...")

env = env  # noqa: F821

# Task 1: If there'is any active pricelist, enable the pricelist feature in settings
active_pricelist_count = env['product.pricelist'].sudo().search_count(
    [('active', '=', True)], limit=1
)
if active_pricelist_count:
    _logger.info("Found %d active pricelists, enabling pricelist feature in settings", active_pricelist_count)
    # Add group_product_pricelist to the default user group
    group_user = env.ref('base.group_user').sudo()
    pricelist_group = env.ref('product.group_product_pricelist')
    if pricelist_group not in group_user.implied_ids:
        _logger.info("Starting to apply group_product_pricelist to group_user")
        group_user.implied_ids |= pricelist_group
    # Ensure pricelists are activated or created for companies
    _logger.info("activating or creating pricelists for companies")
    env['res.company']._activate_or_create_pricelists()
# Task 1: End

# Task 2: Ensure tracking numbers are enabled if product_expiry is installed
if env['ir.module.module'].sudo().search_count(
    [('name', '=', 'product_expiry'), ('state', '=', 'installed')],
    limit=1
):
    _logger.info("product_expiry module is installed, enabling tracking numbers")
    from odoo.addons.product_expiry import _enable_tracking_numbers
    _enable_tracking_numbers(env)
# Task 2: End

env.cr.commit()
_logger.info("Finished post-migration_1_0_init_setup script")