import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration.py script ...")

env = env  # noqa: F821

# Write custom script here
bounce_alias_12 = env["ir.config_parameter"].search([
    ("key", "=", "mail.bounce.alias.12.0")
], limit=1)
if bounce_alias_12:
    bounce_alias = env["ir.config_parameter"].search([
        ("key", "=", "mail.bounce.alias")
    ], limit=1)
    if bounce_alias:
        # Reset value as it's from 12.0
        _logger.info("Reset mail.bounce.alias value to %s ...", bounce_alias_12.value)
        bounce_alias.value = bounce_alias_12.value
        bounce_alias_12.unlink()
    else:
        # Else: reset the key as it's from 12.0
        bounce_alias_12.key = "mail.bounce.alias"

env.cr.commit()
