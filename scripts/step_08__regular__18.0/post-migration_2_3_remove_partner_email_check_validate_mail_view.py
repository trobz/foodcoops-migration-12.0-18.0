import logging

_logger = logging.getLogger(__name__)
_logger.info(
    "Executing post-migration_2_3_remove_partner_email_check_validate_mail_view.py script ..."
)

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")


def remove_partner_email_check_validate_mail_view(env):
    # Remove only the orphaned view with key
    # partner_email_check.view_base_config_settings_validate_mail.
    candidate_views = env["ir.ui.view"].search([
        ("key", "=", "partner_email_check.view_base_config_settings_validate_mail"),
    ])
    removed_count = 0
    skipped_count = 0

    for view in candidate_views:
        _logger.info(
            "Removing orphan view with key %s (%s).",
            view.key,
            view.id,
        )
        view.unlink()
        removed_count += 1

    _logger.info(
        "Processed %d candidate views for key partner_email_check.view_base_config_settings_validate_mail: %d removed, %d skipped.",
        len(candidate_views),
        removed_count,
        skipped_count,
    )


remove_partner_email_check_validate_mail_view(env=env)

env.cr.commit()
_logger.info(
    "Finished post-migration_2_3_remove_partner_email_check_validate_mail_view.py script"
)
