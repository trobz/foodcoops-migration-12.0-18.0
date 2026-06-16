import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_1_7_set_chatter_position_bottom.py script ...")

env = globals().get("env")
if env is None:
    raise RuntimeError("This script must be executed from oow with an injected Odoo env")

def _column_exists(env, table, column):
    env.cr.execute("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = %s AND column_name = %s
    """, (table, column))
    return bool(env.cr.fetchone())

if _column_exists(env, 'res_users', 'chatter_position'):
    # Set default chatter position to 'bottom' for all users
    env.cr.execute("""
        UPDATE res_users
        SET chatter_position = 'bottom'
    """)
    env.cr.commit()
    _logger.info("Set default chatter position to 'bottom' for all users.")

_logger.info("Finished post-migration_1_7_set_chatter_position_bottom.py script")
