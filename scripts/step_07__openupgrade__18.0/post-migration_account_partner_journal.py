import logging
from openupgradelib import openupgrade, openupgrade_180

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_account_partner_journal.py script ...")

env = env  # noqa: F821

# convert_company_dependent gets the old values from ir_property. So, not work in this case.
# openupgrade_180.convert_company_dependent(
#     env, "res.partner", "default_purchase_journal_id"
# )

# Migrate default_purchase_journal_id from temp field to company-dependent field
_logger.info("Migrating default_purchase_journal_id to company-dependent field...")

# Update using SQL for performance with large dataset
# Company-dependent fields are stored as JSONB with structure: {"company_id": value}
env.cr.execute("""
    UPDATE res_partner
    SET default_purchase_journal_id = jsonb_build_object(
        COALESCE(company_id::text, (SELECT id::text FROM res_company ORDER BY id LIMIT 1)),
        default_purchase_journal_id_temp
    )
    WHERE default_purchase_journal_id_temp IS NOT NULL
""")
updated_count = env.cr.rowcount
_logger.info("Updated %d partners with default_purchase_journal_id", updated_count)

# Drop the temporary column
_logger.info("Dropping temporary column default_purchase_journal_id_temp...")
env.cr.execute("ALTER TABLE res_partner DROP COLUMN IF EXISTS default_purchase_journal_id_temp")

env.cr.commit()
_logger.info("Finished post-migration_account_partner_journal.py script")
