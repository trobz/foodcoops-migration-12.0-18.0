import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_3_fix_memberspace_qweb_bootstrap_attrs.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

legacy_to_new = {
    "data-toggle": "data-bs-toggle",
    "data-target": "data-bs-target",
}

dependency_model = env["ir.module.module.dependency"]
child_modules = env["ir.module.module"].search([
    ("state", "=", "installed"),
    ("dependencies_id", "in", dependency_model.search([("name", "=", "coop_memberspace")]).ids),
])


def _view_module_name(view):
    key = view.key or ""
    return key.split(".", 1)[0] if "." in key else False


def _belongs_to_child_module(view, module_names):
    current = view
    seen_ids = set()
    while current and current.id not in seen_ids:
        seen_ids.add(current.id)
        if _view_module_name(current) in module_names:
            return True
        current = current.inherit_id
    return False

if not child_modules:
    _logger.info("No installed child modules found for coop_memberspace.")
else:
    module_names = child_modules.mapped("name")
    _logger.info("Found %s installed child module(s): %s", len(module_names), ", ".join(module_names))

    candidate_views = env["ir.ui.view"].with_context(active_test=False).search([
        ("type", "=", "qweb"),
        "|",
        ("arch_db", "ilike", "data-toggle"),
        ("arch_db", "ilike", "data-target"),
    ])
    qweb_views = candidate_views.filtered(
        lambda view: _belongs_to_child_module(view, module_names)
    )

    fixed_count = 0

    for view in qweb_views:
        arch_db = view.arch_db or ""
        if not any(legacy in arch_db for legacy in legacy_to_new):
            continue

        updated_arch = arch_db
        for legacy, new in legacy_to_new.items():
            updated_arch = updated_arch.replace(legacy, new)

        if updated_arch == arch_db:
            continue

        view.arch_db = updated_arch
        fixed_count += 1
        _logger.info("Updated QWeb view %s (%s).", view.key or view.name, view.id)

    _logger.info("Fixed %s QWeb view(s) in child modules of coop_memberspace.", fixed_count)

env.cr.commit()
_logger.info("Finished post-migration_1_3_fix_memberspace_qweb_bootstrap_attrs.py script")