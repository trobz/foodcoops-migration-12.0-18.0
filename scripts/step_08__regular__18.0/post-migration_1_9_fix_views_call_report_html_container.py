import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_9_fix_views_call_report_html_container.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

legacy_to_new = {
    "report.html_container": "web.html_container",
}

if True:
    candidate_views = env["ir.ui.view"].with_context(active_test=False).search([
        ("type", "=", "qweb"),
        ("arch_db", "ilike", "report.html_container"),
    ])
    fixed_count = 0

    for view in candidate_views:
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

env.cr.commit()
_logger.info("Finished post-migration_1_9_fix_views_call_report_html_container.py script")