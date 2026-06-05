import logging

_logger = logging.getLogger(__name__)

env = env  # noqa: F821

PARAM_KEY = "migration.uom.product_uom_kgm.rounding"

_logger.info("Executing post-migration_1_4_restore_uom_kg_rounding.py script ...")

icp_sudo = env["ir.config_parameter"].sudo()
stored_rounding = icp_sudo.get_param(PARAM_KEY)

if not stored_rounding:
    _logger.info("No preserved rounding found in %s", PARAM_KEY)
else:
    kg_uom = env.ref("uom.product_uom_kgm", raise_if_not_found=False)
    if not kg_uom:
        _logger.warning("Could not find uom.product_uom_kgm to restore rounding")
    else:
        kg_uom.rounding = float(stored_rounding)
        _logger.info(
            "Restored %s rounding to %s",
            kg_uom.display_name,
            stored_rounding,
        )
    icp_sudo.search([("key", "=", PARAM_KEY)]).unlink()

env.cr.commit()