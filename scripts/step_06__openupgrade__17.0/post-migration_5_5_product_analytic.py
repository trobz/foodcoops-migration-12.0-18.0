import logging
import json

_logger = logging.getLogger(__name__)

env = env  # noqa: F821


def migrate_product_category_analytic_accounts():
    """
    Migrate income_analytic_account_id and expense_analytic_account_id from 
    product.category to account.analytic.distribution.model records.
    
    Since the fields have been removed in 18.0, we read from ir_property table.
    """
    _logger.info("Migrating analytic accounts from product categories to distribution models")
    
    # Query ir_property for product category analytic accounts
    env.cr.execute("""
        SELECT DISTINCT
            SPLIT_PART(value_reference, ',', 2)::integer AS analytic_account_id,
            SPLIT_PART(res_id, ',', 2)::integer AS category_id,
            company_id
        FROM ir_property
        WHERE name IN ('expense_analytic_account_id', 'income_analytic_account_id')
            AND res_id LIKE 'product.category,%%'
            AND value_reference IS NOT NULL
            AND value_reference LIKE 'account.analytic.account,%%'
    """)
    
    results = env.cr.fetchall()
    _logger.info(f"Found {len(results)} analytic account configurations for product categories")
    
    for analytic_account_id, category_id, company_id in results:
        # Load the records to get names for logging
        category = env["product.category"].browse(category_id)
        analytic_account = env["account.analytic.account"].browse(analytic_account_id)
        
        if not category.exists() or not analytic_account.exists():
            _logger.warning(
                f"Skipping: category {category_id} or analytic account {analytic_account_id} no longer exists"
            )
            continue
        
        analytic_distribution = {
            str(analytic_account_id): 100.0
        }
        
        env["account.analytic.distribution.model"].create({
            "product_categ_id": category_id,
            "analytic_distribution": analytic_distribution,
            "company_id": company_id or False,
        })
        
        _logger.info(
            f"Created distribution model for category {category.name} "
            f"(ID: {category_id}) -> analytic account {analytic_account.name}"
        )
    
    _logger.info("Completed migration of product category analytic accounts")


def migrate_product_template_analytic_accounts():
    """
    Migrate income_analytic_account_id and expense_analytic_account_id from 
    product.template to account.analytic.distribution.model records linked to product.product.
    
    Since the fields have been removed in 18.0, we read from ir_property table.
    """
    _logger.info("Migrating analytic accounts from product templates to distribution models")
    
    # Query ir_property for product template analytic accounts
    env.cr.execute("""
        SELECT DISTINCT
            SPLIT_PART(value_reference, ',', 2)::integer AS analytic_account_id,
            SPLIT_PART(res_id, ',', 2)::integer AS template_id,
            company_id
        FROM ir_property
        WHERE name IN ('expense_analytic_account_id', 'income_analytic_account_id')
            AND res_id LIKE 'product.template,%%'
            AND value_reference IS NOT NULL
            AND value_reference LIKE 'account.analytic.account,%%'
    """)
    
    results = env.cr.fetchall()
    _logger.info(f"Found {len(results)} analytic account configurations for product templates")
    
    for analytic_account_id, template_id, company_id in results:
        # Load the template and get all its product variants
        template = env["product.template"].browse(template_id)
        analytic_account = env["account.analytic.account"].browse(analytic_account_id)
        
        if not template.exists() or not analytic_account.exists():
            _logger.warning(
                f"Skipping: template {template_id} or analytic account {analytic_account_id} no longer exists"
            )
            continue
        
        # Get all product.product variants for this template
        products = env["product.product"].search([("product_tmpl_id", "=", template_id)])
        
        for product in products:
            analytic_distribution = {
                str(analytic_account_id): 100.0
            }
            
            env["account.analytic.distribution.model"].create({
                "product_id": product.id,
                "analytic_distribution": analytic_distribution,
                "company_id": company_id or False,
            })
            
            _logger.info(
                f"Created distribution model for product {product.name} "
                f"(ID: {product.id}) -> analytic account {analytic_account.name}"
            )
    
    _logger.info("Completed migration of product template analytic accounts")


# Execute migration functions
migrate_product_category_analytic_accounts()
migrate_product_template_analytic_accounts()

# Commit changes
env.cr.commit()

_logger.info("Product analytic migration completed successfully")
