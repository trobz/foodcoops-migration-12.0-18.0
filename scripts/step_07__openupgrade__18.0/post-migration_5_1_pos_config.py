import logging

_logger = logging.getLogger(__name__)

def migrate_shared_cash_payment_methods(env):
    """
    In Odoo 18, cash payment methods cannot be shared between multiple POS configs.
    This function identifies such shared cash payment methods and creates separate
    copies for each POS config that shares them.
    
    Args:
        env: Odoo environment
    """
    PosConfig = env['pos.config']
    PosPaymentMethod = env['pos.payment.method']
    AccountJournal = env['account.journal']

    # Find all POS configs
    all_configs = PosConfig.search([])
    _logger.info("Found %d POS configurations", len(all_configs))

    # Group configs by their cash payment methods
    cash_pm_to_configs = {}
    for config in all_configs:
        for payment_method in config.payment_method_ids:
            if payment_method.journal_id and payment_method.journal_id.type == 'cash':
                if payment_method.id not in cash_pm_to_configs:
                    cash_pm_to_configs[payment_method.id] = []
                cash_pm_to_configs[payment_method.id].append(config)

    # Process each shared cash payment method
    for cash_pm_id, configs in cash_pm_to_configs.items():
        if len(configs) > 1:
            _logger.info("Cash payment method %d is shared by %d POS configs", cash_pm_id, len(configs))
            original_pm = PosPaymentMethod.browse(cash_pm_id)
            
            # Keep the first config with the original payment method
            # Create new ones for the rest
            for config in configs[1:]:
                _logger.info("Creating new cash payment method for POS config: %s (ID: %d)", config.name, config.id)
                
                # Copy the cash journal for this config
                new_journal = original_pm.journal_id.copy({
                    'name': f"{original_pm.journal_id.name} (Copied)",
                    'code': f"CSH{config.id}",
                })
                _logger.info("Copied cash journal: %s (ID: %d)", new_journal.name, new_journal.id)
                
                # Copy the payment method for this config
                new_pm = original_pm.copy({
                    'journal_id': new_journal.id,
                })
                _logger.info("Copied cash payment method: %s (ID: %d)", new_pm.name, new_pm.id)
                
                # Replace the old payment method with the new one in the config
                config.write({
                    'payment_method_ids': [(3, original_pm.id), (4, new_pm.id)]
                })
                _logger.info("Updated POS config %s to use new payment method", config.name)

    _logger.info("Finished processing shared cash payment methods")

def migrate_receipt_options(env):
    """
    Migrate receipt options from ir.config_parameter to pos.config field.
    
    Args:
        env: Odoo environment
    """
    PosConfig = env['pos.config']
    icp_sudo = env['ir.config_parameter'].sudo()
    receipt_options = icp_sudo.get_param('point_of_sale.receipt_options')
    if not receipt_options:
        _logger.info("No receipt options found in ir.config_parameter")
        return
    _logger.info("Migrating receipt options: %d", receipt_options)
    for config in PosConfig.search([]):
        config.write({'receipt_options': receipt_options})
    _logger.info("Updated receipt options for all POS configurations")

def migrate_partner_pos_email_receipt(env):
    """
    Migrate res.partner boolean fields (email_pos_receipt, no_email_pos_receipt)
    from v12 to single selection field pos_email_receipt in v18.
    
    Logic:
    - If email_pos_receipt=True: set pos_email_receipt='email_pos_receipt'
    - If no_email_pos_receipt=True: set pos_email_receipt='no_email_pos_receipt'
    - Priority: email_pos_receipt takes precedence if both are True
    
    Args:
        env: Odoo environment
    """
    Partner = env['res.partner']
    
    # Check if old fields exist in database
    env.cr.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name='res_partner' 
        AND column_name IN ('email_pos_receipt', 'no_email_pos_receipt')
    """)
    existing_columns = [row[0] for row in env.cr.fetchall()]
    
    if not existing_columns:
        _logger.info("Old boolean fields not found in res_partner, skipping migration")
        return
    
    _logger.info("Found old boolean fields: %s", existing_columns)
    
    # Migrate partners with email_pos_receipt=True
    if 'email_pos_receipt' in existing_columns:
        env.cr.execute("""
            UPDATE res_partner 
            SET pos_email_receipt = 'email_pos_receipt'
            WHERE email_pos_receipt = true
        """)
        count = env.cr.rowcount
        _logger.info("Migrated %d partners with email_pos_receipt=True", count)
    
    # Migrate partners with no_email_pos_receipt=True (only if email_pos_receipt is not already set)
    if 'no_email_pos_receipt' in existing_columns:
        env.cr.execute("""
            UPDATE res_partner 
            SET pos_email_receipt = 'no_email_pos_receipt'
            WHERE no_email_pos_receipt = true
            AND (pos_email_receipt IS NULL OR pos_email_receipt != 'email_pos_receipt')
        """)
        count = env.cr.rowcount
        _logger.info("Migrated %d partners with no_email_pos_receipt=True", count)
    
    _logger.info("Finished migrating partner POS email receipt preferences")

_logger.info("Executing post-migration_pos_config.py script ...")

env = env  # noqa: F821

migrate_shared_cash_payment_methods(env)
migrate_receipt_options(env)
migrate_partner_pos_email_receipt(env)

env.cr.commit()
_logger.info("Finished post-migration_pos_config.py script")