import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_6_fix_memberspace_mywork_ftop.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

replacements = [
    ("t-esc=", "t-out="),
    ("<th>Date</th>", '<th name="date">Date</th>'),
    ("<th>Hour</th>", '<th name="hour">Hour</th>'),
    ("<th>Coordinators</th>", '<th name="coordinators">Coordinators</th>'),
    ("<th>Cancellation</th>", '<th name="cancellation">Cancellation</th>'),
    ("<th>Week</th>", '<th name="week">Week</th>'),
    ("<th>Available seats</th>", '<th name="available_seats">Available seats</th>'),
    ("<th>Inscription</th>", '<th name="inscription">Inscription</th>'),
]

env.cr.execute(
        """
        SELECT v.id
        FROM ir_ui_view AS v
        LEFT JOIN ir_model_data AS imd
                ON imd.model = 'ir.ui.view'
             AND imd.res_id = v.id
        WHERE v.key = 'coop_memberspace.mywork_ftop'
            AND imd.id IS NULL
        """
)
rows = env.cr.fetchall()

fixed_count = 0

for (view_id,) in rows:
    view = env["ir.ui.view"].browse(view_id).exists()
    if not view:
        continue

    arch_db = view.arch_db or ""
    updated_arch = arch_db
    for legacy, new in replacements:
        updated_arch = updated_arch.replace(legacy, new)

    if updated_arch == arch_db:
        continue

    view.arch_db = updated_arch
    fixed_count += 1
    _logger.info("Updated orphan mywork_ftop view %s", view_id)

_logger.info("Updated %s orphan mywork_ftop view(s)", fixed_count)

env.cr.commit()
_logger.info("Finished post-migration_1_6_fix_memberspace_mywork_ftop.py script")