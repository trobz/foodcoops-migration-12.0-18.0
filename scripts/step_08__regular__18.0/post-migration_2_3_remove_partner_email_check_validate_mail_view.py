import logging

_logger = logging.getLogger(__name__)
_logger.info(
    "Executing post-migration_2_3_remove_partner_email_check_validate_mail_view.py script ..."
)

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")


def remove_partner_email_check_validate_mail_view(env):
    # Remove view by XML ID
    view = env.ref("partner_email_check.view_base_config_settings_validate_mail", raise_if_not_found=False)
    if view:
        _logger.info(
            "Removing view by XML ID partner_email_check.view_base_config_settings_validate_mail (res_id: %s).",
            view.id,
        )
        view.unlink()
        _logger.info("View successfully removed.")
    else:
        _logger.info(
            "View with XML ID partner_email_check.view_base_config_settings_validate_mail not found, skipping."
        )


remove_partner_email_check_validate_mail_view(env=env)

env.cr.commit()
_logger.info(
    "Finished post-migration_2_3_remove_partner_email_check_validate_mail_view.py script"
)
