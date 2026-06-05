import logging

_logger = logging.getLogger(__name__)

env = env  # noqa: F821

_logger.info("Executing post-migration_1_5_delete_product_template_type_default.py script ...")

field = env["ir.model.fields"].sudo().search([
    ("model", "=", "product.template"),
    ("name", "=", "type"),
], limit=1)

if not field:
    _logger.warning("Could not find field product.template.type")
else:
    defaults = env["ir.default"].sudo().search([("field_id", "=", field.id)])
    if defaults:
        _logger.info(
            "Deleting %s ir.default record(s) for product.template.type",
            len(defaults),
        )
        defaults.unlink()
    else:
        _logger.info("No ir.default record found for product.template.type")

env.cr.commit()