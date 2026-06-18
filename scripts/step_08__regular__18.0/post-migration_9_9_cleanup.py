import uuid
import logging
import psycopg2


_logger = logging.getLogger(__name__)
_logger.info("Executing post-migration.py script...")

TABLES_TO_PRESERVE = [
    # List of table names:
    # "project_project",
]
COLUMNS_TO_PRESERVE = {
    # Dict with table names as keys and list of column names as values:
    # "project_project": ["name", "user_id"],
    # odoo module auth_signup that is auto installed
    "res_partner": ["signup_token"],
}
MODELS_TO_PRESERVE = [
    # List of model names:
    # "project.project",
]
FIELDS_TO_PRESERVE = {
    # Dict with model names as keys and list of column names as values:
    # "project.project": ["name", "user_id"],
    # odoo module auth_signup that is auto installed
    "res.partner": ["signup_token"],
}

try:
    # Odoo >= 18.0
    from odoo.modules.module import load_manifest
except ImportError:
    # Odoo < 18.0
    from odoo.modules.module import (
        load_information_from_description_file as load_manifest,
    )

env = env  # noqa: F821

# Write custom script here
    
def clean_models_from_uninstalled_modules(env):
    """Clean models from uninstalled modules."""
    try:
        purge_models = env["cleanup.purge.wizard.model"].create({})
    except Exception as e:
        _logger.info(f"No models to purge: '{str(e)}'")
        return
    
    try:
        lines = purge_models.purge_line_ids
        if MODELS_TO_PRESERVE:
            lines = lines.filtered(lambda ln: ln.name not in MODELS_TO_PRESERVE)
        _logger.info(
            "Start purging the following models: {}".format(lines.mapped("name"))
        )
        lines_in_error = lines.browse()
        # As a model could depend on another one, postpone its purge until we purged
        # as many models as possible. Stop the loop as soon an error occurs again
        # while purging an already processed model.
        
        total = len(lines)
        cleaned = 0
        
        while lines:
            line = lines[:1]
            try:
                _logger.info("Try to purge: %s" % line.name)
                with env.cr.savepoint():
                    line.purge()
                    cleaned += 1
            except Exception:
                if line in lines_in_error:
                    # Entering in an infinite loop, break here with an error
                    _logger.info(
                        "Some models haven't been purged, check the logs above."
                    )
                    break
                # Postpone the line to purge it at the end
                lines -= line
                lines += line
                # Flag it as errored
                lines_in_error |= line
            else:
                lines -= line
                lines_in_error -= line
    except Exception as e:
        _logger.info(f"Cleanup resulted in error: '{str(e)}'")
        
    _logger.info("Model cleanup completed: %s/%s removed", cleaned, total)
        
def clean_columns_or_fields_from_uninstalled_modules(env, wizard_name):
    """Clean columns/fields from uninstalled modules."""
    try:
        purge_wizard = env[wizard_name].create({})
        purge_wizard_lines = purge_wizard.purge_line_ids
        if TABLES_TO_PRESERVE:
            purge_wizard_lines = purge_wizard_lines.filtered(
                lambda ln: env[ln.model_id.model]._table not in TABLES_TO_PRESERVE
            )
        if MODELS_TO_PRESERVE:
            purge_wizard_lines = purge_wizard_lines.filtered(
                lambda ln: ln.model_id.model not in MODELS_TO_PRESERVE
            )
        if COLUMNS_TO_PRESERVE:
            purge_wizard_lines = purge_wizard_lines.filtered(
                lambda ln: ln.name
                not in COLUMNS_TO_PRESERVE.get(env[ln.model_id.model]._table, [])
            )
        if FIELDS_TO_PRESERVE:
            purge_wizard_lines = purge_wizard_lines.filtered(
                lambda ln: ln.name not in FIELDS_TO_PRESERVE.get(ln.model_id.model, [])
            )
        
        total = len(purge_wizard_lines)
        cleaned = 0
        
        for purge_wizard_line in purge_wizard_lines:
            # Sometimes we cannot control the dependencies of a SQL object
            # against a column that has to be purged: e.g. SQL views created
            # by standard addons and depending on every columns of a given
            # table (even custom columns).
            # Better to not block the migration in such cases.
            try:
                # Create our own savepoint without 'cr.savepoint()' helper to
                # avoid the call to 'RELEASE SAVEPOINT'. Indeed as 'purge()'
                # method used below is calling 'cr.commit()', the current
                # savepoint is automatically released if everything went well,
                # so we only need to handle the ROLLBACK.
                name = uuid.uuid1().hex
                env.cr.execute('SAVEPOINT "%s"' % name)
                _logger.info(
                    "Try to purge column: %s.%s"
                    % (
                        env[purge_wizard_line.model_id.model]._table,
                        purge_wizard_line.name,
                    )
                )
                purge_wizard_line.purge()
                cleaned += 1
            except psycopg2.errors.DependentObjectsStillExist as e:
                _logger.info(f"Purge error: '{str(e)}'")
                env.cr.execute('ROLLBACK TO SAVEPOINT "%s"' % name)
                
        _logger.info(
            "%s cleanup completed: %s/%s removed",
            wizard_name,
            cleaned,
            total,
        )
    except Exception as e:
        _logger.info(f"Cleanup resulted in error: '{str(e)}'")
        
def clean_fields_from_uninstalled_modules(env):
    """Clean field from uninstalled modules."""
    _logger.info("Start purging fields")
    clean_columns_or_fields_from_uninstalled_modules(env, "cleanup.purge.wizard.field")
    
def clean_columns_from_uninstalled_modules(env):
    """Clean columns from uninstalled modules."""
    _logger.info("Start purging columns")
    clean_columns_or_fields_from_uninstalled_modules(env, "cleanup.purge.wizard.column")
    
def clean_db_tables(env, count_clean):
    """Clean tables from uninstalled modules."""
    is_table_cleaned = True
    _logger.info(f"Start purging tables attempt n° {count_clean}")
    try:
        purge_tables = env["cleanup.purge.wizard.table"].create({})
        purge_table_lines = purge_tables.purge_line_ids
        if TABLES_TO_PRESERVE:
            purge_table_lines = purge_table_lines.filtered(
                lambda ln: ln.name not in TABLES_TO_PRESERVE
            )
        
        total = len(purge_table_lines)
        cleaned = 0
        
        for purge_table_line in purge_table_lines:
            _logger.info("Try to purge table: %s" % purge_table_line.name)
            try:
                with env.cr.savepoint():
                    purge_table_line.purge()
                    cleaned += 1
            except Exception:
                is_table_cleaned = False
                
        _logger.info("Table cleanup: %s/%s removed", cleaned, total)
    except Exception as e:
        _logger.info(f"Cleanup resulted in error: '{str(e)}'")
    return is_table_cleaned
    
def clean_models_data_from_uninstalled_modules(env):
    """Clean models data from uninstalled modules."""
    _logger.info("Start purging datas")
    try:
        purge_datas = env["cleanup.purge.wizard.data"].create({})
        purge_data_lines = purge_datas.purge_line_ids.filtered(
            # Metadata exported, imported or from setup must not be deleted
            lambda ln: "__export__" not in ln.name
            and "__setup__" not in ln.name
            and "__import__" not in ln.name
        )
        
        total = len(purge_data_lines)
        cleaned = 0
        
        for purge_data_line in purge_data_lines:
            _logger.info("Try to purge data: %s" % purge_data_line.name)
            purge_data_line.purge()
            cleaned += 1
            
        _logger.info("Data cleanup completed: %s/%s removed", cleaned, total)
    except Exception as e:
        _logger.info(f"Cleanup resulted in error: '{str(e)}'")
        
def clean_menus_from_uninstalled_modules(env):
    """Clean menus from uninstalled modules."""
    _logger.info("Start purging menus")
    try:
        purge_menus = env["cleanup.purge.wizard.menu"].create({})
        purge_menu_lines = purge_menus.purge_line_ids
        
        total = len(purge_menu_lines)
        cleaned = 0
        
        for purge_menu_line in purge_menu_lines:
            _logger.info("Try to purge menu: %s" % purge_menu_line.name)
            purge_menu_line.purge()
            cleaned += 1
            
        _logger.info("Menu cleanup completed: %s/%s removed", cleaned, total)
    except Exception as e:
        _logger.info(f"Cleanup resulted in error: '{str(e)}'")
    
def database_cleanup(env):
    """Clean database"""

    clean_models_from_uninstalled_modules(env=env)
    clean_fields_from_uninstalled_modules(env=env)
    clean_columns_from_uninstalled_modules(env=env)

    to_clean = True
    count_clean = 0
    while to_clean:
        count_clean += 1
        to_clean = not clean_db_tables(env, count_clean)

    clean_models_data_from_uninstalled_modules(env=env)
    clean_menus_from_uninstalled_modules(env=env)
    
def purge_migration_sql_objects(env):
    # Clean the SQL objects created earlier in pre-core to handle upgrade of views
    queries = [
        """
        DROP TRIGGER IF EXISTS trigger_enable_views_for_upgraded_addons
        ON ir_module_module;
        """,
        """
        DROP FUNCTION IF EXISTS enable_views_for_upgraded_addons;
        """,
    ]
    for query in queries:
        env.cr.execute(query)

def drop_openupgrade_legacy_13_0_binding_type(env):
    # Clean the SQL objects created earlier in pre-core to handle upgrade of views
    queries = [
        """
        ALTER TABLE ir_actions 
        DROP COLUMN IF EXISTS openupgrade_legacy_13_0_binding_type CASCADE;
        """,
    ]
    for query in queries:
        env.cr.execute(query)

def clean_unavailable_modules(env):
    """Clean unavailable modules

    When we migrate a project,
    we have a lot of modules which became unavailable in the new version.
    This function will clean the module list to delete unavailable modules.
    """
    module_model = env["ir.module.module"]
    all_modules = module_model.search(
        [
            # Here we need to list:
            # all modules uninstalled we want to migrate
            # to avoid to remove them
            # Example:
            # (
            #     'name',
            #     'not in',
            #     [
            #         'account_asset_management',              # To migrate!
            #     ]
            # )
        ]
    )
    
    removed_count = 0
    skipped_count = 0
    
    for module in all_modules:
        info = load_manifest(module.name)
        if not info:
            if module.state in ["uninstalled", "uninstallable"]:
                _logger.info("MODULE UNAVAILABLE (will be deleted) : %s", module.name)
                
                if env["ir.model.data"].search([("module", "=", module.name)]):
                    _logger.info(
                        " CAN'T UNLINK MODULE, HAS METADATA: %s", 
                        module.name
                    )
                    skipped_count += 1
                else:
                    module.unlink()
                    removed_count += 1
            else:
                _logger.info(
                    "MODULE UNAVAILABLE BUT BAD STATE : %s (%s)",
                    module.name, module.state
                )
                skipped_count += 1
    
    _logger.info(
        "Cleanup summary: %d modules removed, %d skipped", 
        removed_count, skipped_count
    )
    module_model.update_list()
    
def repair_missing_menu_icons(env):
    menus = env["ir.ui.menu"].search([("web_icon", "!=", False)])
    for menu in menus:
        menu.web_icon_data = menu._compute_web_icon_data(menu.web_icon)
        
def cleanup_home_actions_from_users(env):
    # Some home actions configured on users doesn't exist anymore and
    # a blank page is rendered once logged.
    # It happens there is no foreign key on the 'res_users.action_id' field
    # (checked on 13.0, 14.0 and 15.0 databases), so if the action is removed
    # during the migration process, a ghost ID remains in this column.
    query = """
        UPDATE res_users
        SET action_id = NULL
        WHERE action_id NOT IN (
            SELECT id FROM ir_actions
        );
    """
    env.cr.execute(query)

purge_migration_sql_objects(env=env)
drop_openupgrade_legacy_13_0_binding_type(env=env)
database_cleanup(env=env)
clean_unavailable_modules(env=env)
repair_missing_menu_icons(env=env)
cleanup_home_actions_from_users(env=env)

env.cr.commit()
