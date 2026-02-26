import logging

_logger = logging.getLogger(__name__)


def migrate_column_from_journal_to_payment_method(env, colname_aj, colname_ppm, remove_old=True):
    """
    Migrate a column from account.journal to pos.payment.method.
    
    Args:
        env: Odoo environment
        colname_aj: Column name in account_journal table
        colname_ppm: Column name in pos_payment_method table
    """
    # Update field in pos.payment.method from account.journal
    _logger.info(f"Processing payment methods: copying {colname_aj} from account.journal to {colname_ppm} in pos.payment.method")
    env.cr.execute(f"""
        UPDATE pos_payment_method ppm
        SET {colname_ppm} = aj.{colname_aj}
        FROM account_journal aj
        WHERE ppm.name = aj.name
            AND aj.id IS NOT NULL
            AND aj.{colname_aj} IS NOT NULL
    """)
    _logger.info(f"Updated {colname_ppm} for {env.cr.rowcount} payment methods from their journals")

    # comment this code: for this stage: we keep the old field to allow re-run step7 without error, also, 
    # it helps to keep trace of the old field and the new field.
    # # Remove redundant field from account.journal
    # if remove_old:
    #     _logger.info(f"Removing redundant {colname_aj} field from account.journal")
    #     env.cr.execute(f"""
    #         ALTER TABLE account_journal 
    #         DROP COLUMN IF EXISTS {colname_aj}
    #     """)
    #     _logger.info(f"Removed {colname_aj} column from account_journal")


def migrate_fast_payment_for_card_terminals(env):
    """
    Set oca_fast_payment = True for payment methods with card terminal mode.
    
    Args:
        env: Odoo environment
    """
    _logger.info("Setting oca_fast_payment = True for payment methods with card terminal mode")
    env.cr.execute("""
        UPDATE pos_payment_method
        SET oca_fast_payment = TRUE
        WHERE oca_payment_terminal_mode = 'card'
            AND oca_payment_terminal_mode IS NOT NULL
    """)
    _logger.info(f"Updated oca_fast_payment for {env.cr.rowcount} card terminal payment methods")


def migrate_oca_payment_terminal_return(env):
    """
    Copy oca_payment_terminal_return from pos.config to related pos.payment.method records.
    
    Args:
        env: Odoo environment
    """
    _logger.info("Copying oca_payment_terminal_return from pos.config to pos.payment.method")
    env.cr.execute("""
        UPDATE pos_payment_method ppm
        SET oca_payment_terminal_return = pc.oca_payment_terminal_return
        FROM pos_config pc
        JOIN pos_config_pos_payment_method_rel rel ON rel.pos_config_id = pc.id
        WHERE ppm.id = rel.pos_payment_method_id
    """)
    _logger.info(f"Updated oca_payment_terminal_return for {env.cr.rowcount} payment methods from their pos configs")
    
    # comment this code: for this stage: we keep the old field to allow re-run step7 without error, also, 
    # it helps to keep trace of the old field and the new field.
    # # Remove redundant field from pos_config
    # _logger.info("Removing redundant oca_payment_terminal_return field from pos_config")
    # env.cr.execute("""
    #     ALTER TABLE pos_config 
    #     DROP COLUMN IF EXISTS oca_payment_terminal_return
    # """)
    # _logger.info("Removed oca_payment_terminal_return column from pos_config")


def migrate_change_account_id(env):
    """
    Update change_account_id in pos.payment.method by default_account_id from account.journal.
    Then update default_account_id of account.journal by its column oca_change_account_id.
    """
    _logger.info("Migrating change_account_id in pos.payment.method from default_account_id in account.journal")
    env.cr.execute("""
        UPDATE pos_payment_method ppm
        SET change_account_id = aj.default_account_id
        FROM account_journal aj
        WHERE ppm.name = aj.name
            AND aj.id IS NOT NULL
            AND aj.default_account_id IS NOT NULL
            AND aj.oca_change_account_id IS NOT NULL
    """)
    _logger.info(f"Updated change_account_id for {env.cr.rowcount} payment methods from their journals")

    _logger.info("Updating default_account_id in account.journal from oca_change_account_id")
    env.cr.execute("""
        UPDATE account_journal
        SET default_account_id = oca_change_account_id
        WHERE oca_change_account_id IS NOT NULL
    """)
    _logger.info(f"Updated default_account_id for {env.cr.rowcount} journals from oca_change_account_id")


def migrate_credit_terminal_settings(env):
    """
    Set use_payment_terminal and payment_method_type on pos.payment.method
    when related account.journal has oca_is_credit enabled.
    """
    _logger.info("Setting payment terminal fields for credit journals")
    env.cr.execute("""
        UPDATE pos_payment_method ppm
        SET use_payment_terminal = 'credit',
            payment_method_type = 'terminal'
        FROM account_journal aj
        WHERE ppm.name = aj.name
            AND aj.id IS NOT NULL
            AND aj.oca_is_credit IS TRUE
    """)
    _logger.info(f"Updated payment terminal fields for {env.cr.rowcount} credit payment methods")

    # comment this code: for this stage: we keep the old field to allow re-run step7 without error, also, 
    # it helps to keep trace of the old field and the new field.
    # _logger.info("Removing redundant oca_is_credit field from account_journal")
    # env.cr.execute("""
    #     ALTER TABLE account_journal
    #     DROP COLUMN IF EXISTS oca_is_credit
    # """)
    # _logger.info("Removed oca_is_credit column from account_journal")

def migrate_auto_apply_credit_amount(env):
    """
    Set auto_apply_credit_amount on credit payment methods from pos.config flag,
    then drop the migrated column from pos_config.
    """
    _logger.info("Setting auto_apply_credit_amount for credit terminal payment methods")
    env.cr.execute("""
        UPDATE pos_payment_method ppm
        SET auto_apply_credit_amount = TRUE
        FROM pos_config pc
        JOIN pos_config_pos_payment_method_rel rel ON rel.pos_config_id = pc.id
        WHERE ppm.id = rel.pos_payment_method_id
            AND ppm.use_payment_terminal = 'credit'
            AND pc.oca_auto_apply_credit_amount IS TRUE
    """)
    _logger.info(f"Updated auto_apply_credit_amount for {env.cr.rowcount} payment methods from their pos configs")

    
    # comment this code: for this stage: we keep the old field to allow re-run step7 without error, also, 
    # it helps to keep trace of the old field and the new field.
    # _logger.info("Removing redundant oca_auto_apply_credit_amount field from pos_config")
    # env.cr.execute("""
    #     ALTER TABLE pos_config
    #     DROP COLUMN IF EXISTS oca_auto_apply_credit_amount
    # """)
    # _logger.info("Removed oca_auto_apply_credit_amount column from pos_config")

_logger.info("Executing post-post-migration_5_5_pos_payment_method.py script ...")

env = env  # noqa: F821

migrate_column_from_journal_to_payment_method(env, "is_automatic_validation", "is_automatic_validation")
migrate_column_from_journal_to_payment_method(env, "oca_payment_terminal_mode", "oca_payment_terminal_mode")
migrate_column_from_journal_to_payment_method(env, "oca_iface_automatic_cashdrawer", "iface_automatic_cashdrawer")

migrate_fast_payment_for_card_terminals(env)
migrate_oca_payment_terminal_return(env)
migrate_change_account_id(env)
migrate_credit_terminal_settings(env)
migrate_auto_apply_credit_amount(env)

env.cr.commit()
_logger.info("Finished post-post-migration_5_5_pos_payment_method.py script")