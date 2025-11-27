# Project migration foodcoop from v12 to v18 information

### Steps (with explanations) ###

- **Install OpenUpgrade Wizard**  
  Install the OpenUpgrade Wizard tool from https://gitlab.com/odoo-openupgrade-wizard/odoo-openupgrade-wizard.  
  _This tool automates and assists with Odoo database migration between different versions._

- **Fetch migration code for all needed Odoo versions**  
  Clone this repo: `git clone git@gitlab.trobz.com:project/migration-foodcoop-12-18.git` 
  _This downloads the required migration scripts and code for each Odoo version in your migration path (from 12.0 to 18.0)._

- **Pull the codebase**  
  Run: `odoo-openupgrade-wizard get-code` to pull the codebase for all version or 
  Run: `odoo-openupgrade-wizard get-code -v 18.0` to pull the codebase for 18.0 only

- **Build Docker containers for migration environment**  
  Run: `odoo-openupgrade-wizard docker-build`  
  _This builds the Docker environment needed to run the Odoo migration and all dependencies in isolated containers._

- **Restore your database backup for migration**  
  Run:  
  `odoo-openupgrade-wizard restoredb -d foodcoop12_YYYYMMDD --database-path /path/to/dump_db.pgdump --database-format c --filestore-path filestore_path --filestore-format d`  
  _This restores your Odoo v12 database and filestore from your backup files into PostgreSQL, getting it ready for migration._

- **Run the migration process across each Odoo version**  
  Run:  
  `odoo-openupgrade-wizard upgrade --first-step 2 --last-step 8 --database foodcoop12_YYYYMMDD`  
  _This performs the step-by-step upgrades required, migrating the database sequentially through each Odoo version._

- **Export the migrated database and filestore**  
  Run:  
  `odoo-openupgrade-wizard dumpdb -d foodcoop12_YYYMMDD --database-path foodcoop12_migrated_YYYMMDD.dump --database-format c --filestore-path foodcoop12_YYYMMDD --filestore-format d`  
  _After migration, this command dumps the upgraded database and filestore to your host machine for backup or deployment._



## Useful notes:
### query
- check mismatch UOM between product and stock_move line
```
select pp.id as product_id, pt.name, sml.id as move_id, pt.uom_id as product_id, sml.product_uom_id as sml_uom_id from product_template pt join product_product pp on pp.product_tmpl_id=pt.id join stock_move_line sml on pp.id=sml.product_id where pt.uom_id=1 and pt.uom_id != sml.product_uom_id;
```