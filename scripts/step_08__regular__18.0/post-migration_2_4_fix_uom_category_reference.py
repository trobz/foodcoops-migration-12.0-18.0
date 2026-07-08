import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_2_4_fix_uom_category_reference.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")


def fix_uom_category_reference(env):
    """
    Finds all UoM categories without a reference UoM and fixes them.
    - If a category has UoMs but no reference, it sets the first one as reference.
    - If a category has no UoMs, it creates a new reference UoM for it.
    """
    # Using SQL for efficiency to find categories with UoMs but no reference UoM
    env.cr.execute(
        """
        SELECT category_id
        FROM uom_uom
        GROUP BY category_id
        HAVING bool_and(uom_type != 'reference')
    """
    )
    category_ids_with_uoms_no_ref = [row[0] for row in env.cr.fetchall()]

    if category_ids_with_uoms_no_ref:
        _logger.info(
            "Found %d UoM categories with UoMs but no reference. Fixing them...",
            len(category_ids_with_uoms_no_ref),
        )
        categories_to_fix = env["uom.category"].browse(category_ids_with_uoms_no_ref)
        for category in categories_to_fix:
            # Try to find a UoM with factor=1.0 as a candidate for reference
            first_uom = env["uom.uom"].search(
                [("category_id", "=", category.id), ("factor", "=", 1.0)], limit=1
            )
            if first_uom:
                _logger.info(
                    "Setting UoM '%s' (ID: %d) as reference for category '%s' (ID: %d).",
                    first_uom.name,
                    first_uom.id,
                    category.name,
                    category.id,
                )
                first_uom.write({"uom_type": "reference"})
            else:
                uom_name = f"Reference for {category.name}"
                _logger.info(
                    "Creating reference UoM '%s' for category '%s' (ID: %d).",
                    uom_name,
                    category.name,
                    category.id,
                )
                env["uom.uom"].create(
                    {
                        "name": uom_name,
                        "category_id": category.id,
                        "uom_type": "reference",
                        "factor": 1.0,
                        "rounding": 0.01,
                    }
                )

fix_uom_category_reference(env=env)

env.cr.commit()
_logger.info("Finished post-migration_2_4_fix_uom_category_reference.py script")
