import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_0_fix_verouillage_zones.py script ...")

env = env  # noqa: F821

view_name = "{TMT}VerouillageZones"
legacy_xpath = "//field[@name='order_line']/tree/field[@name='product_id']"
fixed_xpath = "//field[@name='order_line']/list/field[@name='product_id']"

views = env["ir.ui.view"].with_context(active_test=False).search([
    ("name", "=", view_name),
])

if not views:
    _logger.info("View %s not found, skipping fix.", view_name)
else:
    fixed_count = 0
    for view in views:
        if legacy_xpath not in (view.arch_db or ""):
            _logger.info("View %s already fixed or does not contain the legacy xpath.", view.display_name)
            continue

        view.arch_db = view.arch_db.replace(legacy_xpath, fixed_xpath)
        fixed_count += 1
        _logger.info("Updated view %s to replace tree with list in xpath.", view.display_name)

    _logger.info("Fixed %s view(s) named %s.", fixed_count, view_name)

env.cr.commit()
_logger.info("Finished post-migration_1_0_fix_verouillage_zones.py script")