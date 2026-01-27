
-- pos_automatic_validation --
ALTER TABLE account_journal RENAME COLUMN iface_automatic_validation TO is_automatic_validation;

-- pos_payment_terminal --
ALTER TABLE pos_config RENAME COLUMN hide_return_to_basket_btn_as_soon_as_payment_line_exists TO pos_payment_terminal_hide_back_btn;
ALTER TABLE account_journal RENAME COLUMN pos_terminal_payment_mode TO oca_payment_terminal_mode;

-- pos_payment_terminal_return --
ALTER TABLE pos_config RENAME COLUMN iface_payment_terminal_return TO oca_payment_terminal_return;

-- pos_transfer_account --
ALTER TABLE pos_config RENAME COLUMN transfer_account_id TO suspense_account_id;
