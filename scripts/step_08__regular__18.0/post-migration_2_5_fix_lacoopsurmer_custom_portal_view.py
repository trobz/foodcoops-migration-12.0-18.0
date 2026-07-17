import logging
from lxml import etree

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_5_fix_lacoopsurmer_custom_portal_view.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")


def fix_lacoopsurmer_custom_portal_view(env):
    """
    Fix portal.portal_my_home views for lacoopsurmer_custom module.
    - Find the view with xmlid (view 1) and the view without xmlid (view 2)
    - Update view 2's arch to match view 1
    - Change my_details t-value from "True" to "False" in view 2
    """
    # Check if lacoopsurmer_custom module is installed
    IrModule = env["ir.module.module"]
    lacoopsurmer_custom = IrModule.search(
        [("name", "=", "lacoopsurmer_custom"), ("state", "=", "installed")], limit=1
    )
    
    if not lacoopsurmer_custom:
        return
        
    IrUiView = env["ir.ui.view"]
    IrModelData = env["ir.model.data"]

    # Find all views with key = 'portal.portal_my_home'
    portal_views = IrUiView.search([("key", "=", "portal.portal_my_home")])
    
    if len(portal_views) < 2:
        _logger.info(
            "Found %d views with key='portal.portal_my_home'. Expected at least 2. Skipping.",
            len(portal_views),
        )
        return

    _logger.info("Found %d views with key='portal.portal_my_home'", len(portal_views))

    # Separate views with and without xmlid
    view_with_xmlid = None
    view_without_xmlid = None

    for view in portal_views:
        # Check if this view has an xmlid
        model_data = IrModelData.search([("model", "=", "ir.ui.view"), ("res_id", "=", view.id)])
        if model_data:
            if view_with_xmlid is None:
                view_with_xmlid = view
                _logger.info("Found view with xmlid: ID=%d, Name=%s", view.id, view.name)
        else:
            if view_without_xmlid is None:
                view_without_xmlid = view
                _logger.info("Found view without xmlid: ID=%d, Name=%s", view.id, view.name)

    if view_with_xmlid is None or view_without_xmlid is None:
        _logger.warning(
            "Could not find both views (with xmlid and without xmlid). Skipping fix."
        )
        return

    # Get the arch from view 1 (with xmlid)
    source_arch = view_with_xmlid.arch

    # Update view 2's arch to match view 1
    _logger.info("Updating view without xmlid (ID=%d) arch to match view with xmlid", view_without_xmlid.id)
    
    # Parse the arch as XML
    try:
        root = etree.fromstring(source_arch.encode("utf-8"))
    except Exception as e:
        _logger.error("Failed to parse source arch as XML: %s", str(e))
        return

    # Find the element with t-set="my_details" and change t-value from "True" to "False"
    for elem in root.iter():
        if elem.get("t-set") == "my_details":
            old_value = elem.get("t-value")
            if old_value == "True":
                elem.set("t-value", "False")
                _logger.info("Changed t-value from 'True' to 'False' for my_details element")
            break

    # Convert modified arch back to string
    modified_arch = etree.tostring(root, encoding="utf-8", method="html").decode("utf-8")

    # Update view 2 with the modified arch
    view_without_xmlid.write({"arch": modified_arch})
    _logger.info("Successfully updated view without xmlid (ID=%d)", view_without_xmlid.id)


def remove_pos_order_line_removal_view(env):
    """Remove the view with xmlid pos_order_line_removal.view_pos_config_form_inherit"""
    try:
        view = env.ref("pos_order_line_removal.view_pos_config_form_inherit", raise_if_not_found=False)
        if view:
            view.unlink()
            _logger.info(
                "Successfully removed view with xmlid: pos_order_line_removal.view_pos_config_form_inherit"
            )
        else:
            _logger.info(
                "View with xmlid pos_order_line_removal.view_pos_config_form_inherit not found"
            )
    except Exception as e:
        _logger.error(
            "Failed to remove view with xmlid pos_order_line_removal.view_pos_config_form_inherit: %s",
            str(e),
        )

fix_lacoopsurmer_custom_portal_view(env)
remove_pos_order_line_removal_view(env)
env.cr.commit()
_logger.info("Successfully completed post-migration_2_5_fix_lacoopsurmer_custom_portal_view.py")
