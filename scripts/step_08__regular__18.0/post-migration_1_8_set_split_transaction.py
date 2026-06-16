import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_8_set_split_transaction.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

# Set default split transactions to true for all payment methods
env.cr.execute("""
    UPDATE pos_payment_method
    SET split_transactions = true
""")
env.cr.commit()
_logger.info("Set default split transactions to true for all payment methods.")
_logger.info("Finished post-migration_1_8_set_split_transaction.py script")
