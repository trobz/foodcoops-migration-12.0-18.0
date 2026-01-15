import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_5_0_account_journal script ...")

env = env  # noqa: F821

# Write custom script here

# Todo: in some coops, they installed account_reconcile_oca. There's a required field `reconcile_mode`
# in account.journal, but its value is not set during migration. We set a default value here.
AccountJournal = env["account.journal"]

# First, make sure the field exists
if "reconcile_mode" not in AccountJournal._fields:
    _logger.warning("Field reconcile_mode does not exist in account.journal, skipping...")
    env.cr.commit()
    exit(0)

journals_without_reconcile_mode = AccountJournal.search([
    ("reconcile_mode", "!=", False),
    ("reconcile_mode", "not in", ("edit", "keep")),
])
_logger.info("Found %d journals which reconcile_mode's incorrect", len(journals_without_reconcile_mode))
for journal in journals_without_reconcile_mode:
    journal.reconcile_mode = "edit"
    _logger.info("Set reconcile_mode='edit' for journal: %s (ID: %d)", journal.name, journal.id)

env.cr.commit()
_logger.info("Finished post-migration_5_0_account_journal script")