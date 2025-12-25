import logging
from openupgradelib import openupgrade, openupgrade_180

_logger = logging.getLogger(__name__)

env = env  # noqa: F821

openupgrade_180.convert_company_dependent(
    env, "res.partner", "default_purchase_journal_id"
)

env.cr.commit()
