import logging

_logger = logging.getLogger(__name__)
_logger.info(
    "Executing post-migration_2_2_remove_account_bank_statement_line_pos_tree_view.py script ..."
)

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")


def remove_orphan_account_bank_statement_line_pos_tree_view(env):
    # Coop TMT note: this view exists without an xmlid in the source database.
    # Remove only the orphaned view named account.bank.statement.line.pos.tree.
    candidate_views = env["ir.ui.view"].search([
        ("name", "=", "account.bank.statement.line.pos.tree"),
    ])
    removed_count = 0
    skipped_count = 0

    for view in candidate_views:
        model_data = env["ir.model.data"].search([
            ("model", "=", "ir.ui.view"),
            ("res_id", "=", view.id),
        ], limit=1)
        if model_data:
            skipped_count += 1
            _logger.info(
                "Skipped view %s (%s) because it has an xmlid (%s.%s).",
                view.name,
                view.id,
                model_data.module,
                model_data.name,
            )
            continue

        _logger.info(
            "Removing orphan view %s (%s) without xmlid for coop TMT.",
            view.name,
            view.id,
        )
        view.unlink()
        removed_count += 1

    _logger.info(
        "Processed %d candidate views for account.bank.statement.line.pos.tree: %d removed, %d skipped.",
        len(candidate_views),
        removed_count,
        skipped_count,
    )


remove_orphan_account_bank_statement_line_pos_tree_view(env=env)

env.cr.commit()
_logger.info(
    "Finished post-migration_2_2_remove_account_bank_statement_line_pos_tree_view.py script"
)
