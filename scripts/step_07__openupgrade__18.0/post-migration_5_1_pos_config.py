import logging

_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration_pos_config.py script ...")

env = env  # noqa: F821

# Fix: Create separate cash payment methods for each POS config
# In Odoo 18, cash payment methods cannot be shared between multiple POS configs

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

env.cr.commit()
_logger.info("Finished post-migration_pos_config script")