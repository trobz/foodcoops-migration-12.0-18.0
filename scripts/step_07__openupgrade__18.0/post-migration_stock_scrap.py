import logging

_logger = logging.getLogger(__name__)

env = env  # noqa: F821

# Write custom script here
# Insert the records from stock.scrap.origin into stock.scrap.reason.tag
ReasonTag = env["stock.scrap.reason.tag"]
existed = ReasonTag.search([], limit=1)
if not existed:
    # Only insert if not existed.
    env.cr.execute("SELECT id, name FROM stock_scrap_origin")
    origins = env.cr.fetchall()
    _logger.info("Inserting the values into stock.scrap.reason.tag ...")
    for (origin_id, origin_name) in origins:
        if not origin_name:
            origin_name = f"Origin Old ID: {origin_id}"
        tag = ReasonTag.create({"name": origin_name})
        sql = f"SELECT id FROM stock_scrap WHERE scrap_origin_id={origin_id}"
        env.cr.execute(sql)
        scraps = env.cr.fetchall()
        for (scrap_id,) in scraps:
            env.cr.execute(
                """
                INSERT INTO stock_scrap_stock_scrap_reason_tag_rel(stock_scrap_id, stock_scrap_reason_tag_id)
                VALUES(%s, %s)
                """,
                [scrap_id, tag.id]
            )

env.cr.commit()
