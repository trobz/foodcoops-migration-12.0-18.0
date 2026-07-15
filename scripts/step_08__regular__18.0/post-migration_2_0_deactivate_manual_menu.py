import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_0_deactivate_manual_menu.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

def deactivate_manual_menu(env):
    # Deactivate the manual menus which are: not link to ir.model.data and has no parent menu.
    # Then, check if any of them are set as home menu for any user, if so, set the home menu to empty.
    candidate_menus = env["ir.ui.menu"].search([
        ("parent_id", "=", False),
    ])
    fixed_count = 0

    for menu in candidate_menus:
        # Check if the menu is linked to any ir.model.data record
        model_data = env["ir.model.data"].search([
            ("model", "=", "ir.ui.menu"),
            ("res_id", "=", menu.id),
        ], limit=1)
        if model_data:
            continue  # Skip menus that are linked to ir.model.data

        if menu.action:
            # Check if the menu is set as home menu for any user
            users_with_home_menu = env["res.users"].search([
                ("action_id", "=", menu.action.id),
            ])
            if users_with_home_menu:
                # If the menu is set as home menu for any user, set their home menu to empty
                users_with_home_menu.write({"action_id": False})
                _logger.info("Unset home menu for %d users who had %s (%s) as their home menu.",
                            len(users_with_home_menu), menu.name, menu.id)
            # unlink the menu if the action model is board.board
            if menu.action.res_model == "board.board":
                _logger.info("Unlinked manual menu %s (%s) with action model board.board.", menu.name, menu.id)
                menu.action.unlink()
                menu.unlink()
                fixed_count += 1
                continue

        # deactivate the menu
        menu.active = False
        fixed_count += 1
        _logger.info("Deactivated manual menu %s (%s).", menu.name, menu.id)

deactivate_manual_menu(env=env)

env.cr.commit()
_logger.info("Finished post-migration_2_0_deactivate_manual_menu.py script")
