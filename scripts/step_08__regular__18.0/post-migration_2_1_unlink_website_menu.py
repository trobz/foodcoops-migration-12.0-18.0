import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_1_unlink_website_menu.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

def deactivate_contactus_button(env):
    # Deactivate the view website.header_call_to_action if exists
    view = env["ir.ui.view"].search([("key", "=", "website.header_call_to_action")], limit=1)
    if view:
        view.active = False
        _logger.info("Deactivated view website.header_call_to_action")

deactivate_contactus_button(env=env)

env.cr.commit()
_logger.info("Finished post-migration_2_1_unlink_website_menu.py script")
