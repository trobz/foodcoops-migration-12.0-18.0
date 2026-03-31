import logging

_logger = logging.getLogger(__name__)

PACKAGE_NAME_PREFIX = "P-"

def _column_exists(env, table, column):
    env.cr.execute("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = %s AND column_name = %s
    """, (table, column))
    return bool(env.cr.fetchone())

def get_or_create_packaging(env, product_id, package_qty):
    Package = env["product.packaging"]
    packaging = Package.search([
        ("product_id", "=", product_id),
        ("qty", "=", package_qty)
    ], limit=1)
    if not packaging:
        product = env["product.product"].browse(product_id)
        display_qty = package_qty
        if int(package_qty) == package_qty:
            display_qty = int(package_qty)
        vals = {
            "name": f"{PACKAGE_NAME_PREFIX}{display_qty}-{product.uom_po_id.name}",
            "qty": package_qty,
            "product_id": product_id
        }
        packaging = Package.create(vals)
    return packaging

def set_packaging_psi(env):
    if not _column_exists(env, "product_supplierinfo", "mig_package_qty"):
        _logger.info("Skipping set_packaging_psi: column mig_package_qty not found in product_supplierinfo")
        return
    _logger.info("Set packaging for Product supplier info ...")
    sql = """
        SELECT psi.id res_id, psi.product_id, product_tmpl_id, mig_package_qty
        FROM product_supplierinfo psi
        JOIN product_template pt ON psi.product_tmpl_id = pt.id
        WHERE mig_package_qty > 0
            AND product_packaging_id ISNULL
            AND pt.active IS True
    """
    env.cr.execute(sql)
    datas = env.cr.fetchall()
    PSI = env["product.supplierinfo"]
    Product = env["product.product"]
    uom_unit = env.ref("uom.product_uom_unit", False)
    for (res_id, pid, product_tmpl_id, mig_package_qty) in datas:
        # _logger.info("Set packaging for psi: %s (%s)", product_tmpl_id, package_qty)
        psi = PSI.browse(res_id)
        # Ignore if package_qty = 1 and uom = Unit
        if mig_package_qty == 1.0 and psi.product_uom == uom_unit:
            continue
        product_ids = []
        if pid:
            # Case wrong psi.product_tmpl_id != product_id.product_tmpl_id
            # Chaudron: product.supplierinfo(15451,)
            #   psi.product_tmpl_id: product.template(13448,)
            #   product.product_tmpl_id: product.template(1249,)
            product = Product.browse(pid)
            if product.product_tmpl_id == psi.product_tmpl_id:
                product_ids.append(pid)
        if not product_ids:
            template = env["product.template"].browse(product_tmpl_id)
            product_ids = template.product_variant_ids.ids

        for product_id in product_ids:
            _logger.info(
                "Set packaging for Product ID: %s, Product Template ID",
                product_id, product_tmpl_id
            )
            packaging = get_or_create_packaging(env, product_id, mig_package_qty)
            if packaging:
                # Update the psi
                if pid and pid != product_id:
                    psi.product_id = False
                psi.product_packaging_id = packaging
    _logger.info("Completed: Set packaging for Product supplier info ...")

def set_packaging_purchase_line(env):
    if not _column_exists(env, "purchase_order_line", "mig_package_qty"):
        _logger.info("Skipping set_packaging_purchase_line: column mig_package_qty not found in purchase_order_line")
        return
    _logger.info("Set packaging for Purchase line ...")
    POLine = env["purchase.order.line"]
    sql = """
        SELECT id res_id, product_id, mig_package_qty, product_qty_package
        FROM purchase_order_line
        WHERE mig_package_qty > 0
            AND product_qty_package > 0
            AND state NOT IN ('done', 'cancel')
            AND product_packaging_id ISNULL
    """
    env.cr.execute(sql)
    datas = env.cr.fetchall()
    uom_unit = env.ref("uom.product_uom_unit", False)
    for (res_id, product_id, mig_package_qty, product_qty_package) in datas:
        purchase_line = POLine.browse(res_id)
        # Ignore if package_qty = 1 and uom = Unit
        if mig_package_qty == 1.0 and purchase_line.product_uom == uom_unit:
            continue
        # Check indicative_package case
        if (
            not purchase_line.indicative_package 
            and int(purchase_line.product_qty / mig_package_qty)
                != (purchase_line.product_qty / mig_package_qty)
        ):
            continue
        _logger.info("Set packaging for POline: %s", purchase_line)
        try:
            packaging = get_or_create_packaging(env, product_id, mig_package_qty)
            if packaging:
                # purchase_line.product_packaging_id = packaging
                sql = """
                    UPDATE purchase_order_line
                    SET product_packaging_id = %s,
                        product_packaging_qty = %s
                    WHERE id = %s
                """
                env.cr.execute(sql, (packaging.id, product_qty_package, res_id))
        except Exception as err:
            _logger.info("Failed by: %s", str(err))
    _logger.info("Completed: Set packaging for Purchase line ...")

def set_packaging_stock_move(env):
    if not _column_exists(env, "stock_move", "product_qty_package"):
        _logger.info("Skipping set_packaging_stock_move: column product_qty_package not found in stock_move")
        return
    _logger.info("Set packaging for Stock move ...")
    sql = """
    WITH raw_data as (
        SELECT sm.id res_id, pol.product_packaging_id
        FROM stock_move sm
            JOIN purchase_order_line pol ON pol.id = sm.purchase_line_id
        WHERE sm.product_qty_package > 0
            AND sm.state NOT IN ('done', 'cancel')
            AND sm.product_packaging_id ISNULL
            AND pol.product_packaging_id NOTNULL
    )
    UPDATE stock_move
    SET product_packaging_id = raw_data.product_packaging_id
    FROM raw_data
    WHERE stock_move.id = raw_data.res_id
    """
    env.cr.execute(sql)
    _logger.info("Completed: Set packaging for Stock Move ...")

env = env  # noqa: F821

# Write custom script here
set_packaging_psi(env)
set_packaging_purchase_line(env)
set_packaging_stock_move(env)

env.cr.commit()
