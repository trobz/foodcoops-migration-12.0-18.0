import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_1_unlink_website_menu.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

def unlink_website_menu_by_url(env):
    # Search all website menus with a URL in the input list and unlink them

    # First check if the website.menu model exists in the current environment
    if "website.menu" not in env:
        _logger.warning("The model 'website.menu' does not exist in the current environment. Skipping unlinking website menus.")
        return

    candidate_menus = env["website.menu"].search([
        ("url", "in", ["/contactus"]),
    ])
    fixed_count = 0
    for menu in candidate_menus:
        menu.unlink()
        fixed_count += 1
    _logger.info("Unlinked %d website menus", fixed_count)

def deactivate_contactus_button(env):
    # Deactivate the view website.header_call_to_action if exists
    view = env["ir.ui.view"].search([("key", "=", "website.header_call_to_action")], limit=1)
    if view:
        view.active = False
        _logger.info("Deactivated view website.header_call_to_action")

unlink_website_menu_by_url(env=env)
deactivate_contactus_button(env=env)

env.cr.commit()
_logger.info("Finished post-migration_2_1_unlink_website_menu.py script")
