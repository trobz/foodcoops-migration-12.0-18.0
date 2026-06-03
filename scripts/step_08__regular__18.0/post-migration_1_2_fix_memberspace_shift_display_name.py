import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_2_fix_memberspace_shift_display_name.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

legacy_expr = "item.shift_id and item.shift_id.name_get()[0][1]"
fixed_expr = "item.shift_id and item.shift_id.display_name"
view_keys = [
    "coop_memberspace.classic_counter",
    "coop_memberspace.ftop_my_counter",
]

fixed_count = 0
views = env["ir.ui.view"].with_context(active_test=False).search([
    ("key", "in", view_keys),
])

if not views:
    _logger.info("No customized memberspace views found for keys: %s", ", ".join(view_keys))

for view in views:
    if legacy_expr not in (view.arch_db or ""):
        _logger.info(
            "View %s does not contain the legacy shift expression, skipping.",
            view.key or view.name,
        )
        continue

    view.arch_db = view.arch_db.replace(legacy_expr, fixed_expr)
    fixed_count += 1
    _logger.info(
        "Updated view %s to use display_name for shift labels.",
        view.key or view.name,
    )

_logger.info("Fixed %s view(s).", fixed_count)

env.cr.commit()
_logger.info("Finished post-migration_1_2_fix_memberspace_shift_display_name.py script")