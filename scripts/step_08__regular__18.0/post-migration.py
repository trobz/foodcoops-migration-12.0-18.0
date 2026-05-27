import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration.py script ...")

env = env  # noqa: F821

# Write custom script here
modules_to_cleanup = env["ir.module.module"].search([
	("state", "in", ["to install", "to upgrade"])
])
if modules_to_cleanup:
	view_data = env["ir.model.data"].search([
		("model", "=", "ir.ui.view"),
		("module", "in", modules_to_cleanup.mapped("name")),
	])
	views_to_cleanup = env["ir.ui.view"].browse(view_data.mapped("res_id")).exists()
	root_views_to_cleanup = views_to_cleanup.filtered(
		lambda view: not view.inherit_id or view.inherit_id not in views_to_cleanup
	)
	if root_views_to_cleanup:
		_logger.info(
			"Removing %s views for modules pending install/upgrade: %s",
			len(views_to_cleanup),
			", ".join(modules_to_cleanup.mapped("name")),
		)
		try:
			root_views_to_cleanup.with_context(_force_unlink=True).unlink()
		except Exception:
			_logger.exception(
				"Failed to remove views for modules pending install/upgrade: %s",
				", ".join(modules_to_cleanup.mapped("name")),
			)

env.cr.commit()
