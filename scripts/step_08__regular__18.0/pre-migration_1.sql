-- capital_subscription 12.0 -> 18.0 removed these view XML IDs:
--   * capital_subscription.view_account_invoice_form
--   * capital_subscription.view_account_invoice_refund_capital_subscription_form
--
-- The 18.0 module replaces them with account.move/account.move.reversal views.
-- If any custom or downstream views still inherit the removed 12.0 views,
-- Odoo cannot delete the obsolete roots during module upgrade because of the
-- ir_ui_view.inherit_id foreign key. Remove the whole inherited subtree first.

CREATE TEMP TABLE tmp_capital_subscription_removed_view_descendants
ON COMMIT DROP AS
WITH RECURSIVE removed_roots AS (
	SELECT view.id
	FROM ir_ui_view view
	JOIN ir_model_data imd
		ON imd.model = 'ir.ui.view'
	   AND imd.res_id = view.id
	WHERE imd.module = 'capital_subscription'
	  AND imd.name IN (
		  'view_account_invoice_form',
		  'view_account_invoice_refund_capital_subscription_form'
	  )
), descendants AS (
	SELECT child.id
	FROM ir_ui_view child
	JOIN removed_roots root
		ON child.inherit_id = root.id

	UNION

	SELECT child.id
	FROM ir_ui_view child
	JOIN descendants parent
		ON child.inherit_id = parent.id
)
SELECT DISTINCT id
FROM descendants;

UPDATE ir_ui_view
SET inherit_id = NULL
WHERE id IN (
	SELECT id
	FROM tmp_capital_subscription_removed_view_descendants
);

DELETE FROM ir_ui_view_custom
WHERE ref_id IN (
	SELECT id
	FROM tmp_capital_subscription_removed_view_descendants
);

DELETE FROM ir_model_data
WHERE model = 'ir.ui.view'
  AND res_id IN (
	  SELECT id
	  FROM tmp_capital_subscription_removed_view_descendants
  );

DELETE FROM ir_ui_view
WHERE id IN (
	SELECT id
	FROM tmp_capital_subscription_removed_view_descendants
);
