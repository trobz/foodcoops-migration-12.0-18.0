ALTER TABLE res_partner RENAME COLUMN default_purchase_journal_id TO default_purchase_journal_id_temp;
ALTER TABLE res_partner ADD COLUMN default_purchase_journal_id jsonb;
UPDATE res_partner SET default_purchase_journal_id = CAST(CAST(default_purchase_journal_id_temp AS text) AS jsonb);