import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_1_fix_simplification_codes_barres.py script ...")

env = env  # noqa: F821

view_name = "{TMT} Simplification Codes barres"
parent_xmlid = "barcodes_generator_product.view_product_template_form"

parent_view = env.ref(parent_xmlid, raise_if_not_found=False)
if not parent_view:
    _logger.info("Parent view %s not found, skipping fix.", parent_xmlid)
else:
    views = env["ir.ui.view"].with_context(active_test=False).search([
        ("name", "=", view_name),
    ])

    if not views:
        _logger.info("View %s not found, skipping fix.", view_name)
    else:
        fixed_count = 0
        for view in views:
            if view.inherit_id == parent_view:
                _logger.info("View %s already inherits from %s.", view.display_name, parent_xmlid)
                continue

            view.inherit_id = parent_view.id
            fixed_count += 1
            _logger.info("Updated view %s to inherit from %s.", view.display_name, parent_xmlid)

        _logger.info("Fixed %s view(s) named %s.", fixed_count, view_name)

env.cr.commit()
_logger.info("Finished post-migration_1_1_fix_simplification_codes_barres.py script")