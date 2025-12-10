
-- Update for product_print_category
WITH raw_data as (
    SELECT pp.id, pt.print_category_id
    FROM product_product pp
    JOIN product_template pt
        ON pp.product_tmpl_id = pt.id
    WHERE pt.print_category_id NOTNULL
        AND pp.print_category_id ISNULL
)
UPDATE product_product
SET print_category_id = raw_data.print_category_id
FROM raw_data
WHERE product_product.id = raw_data.id