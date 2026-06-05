-- In 13.0 the barcode nomenclature is read from the company.
-- Backfill it from existing POS configs when the company value is still empty.
UPDATE res_company AS company
SET nomenclature_id = source.barcode_nomenclature_id
FROM (
    SELECT DISTINCT ON (company_id)
        company_id,
        barcode_nomenclature_id
    FROM pos_config
    WHERE barcode_nomenclature_id IS NOT NULL
    ORDER BY company_id, id
) AS source
WHERE source.company_id = company.id
  AND company.nomenclature_id IS NULL;