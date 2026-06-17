
-- pos_automatic_validation --
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'account_journal' 
          AND column_name = 'iface_automatic_validation'
    ) THEN
        ALTER TABLE account_journal RENAME COLUMN iface_automatic_validation TO is_automatic_validation;
    END IF;
END $$;



-- pos_payment_terminal --
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pos_config' 
          AND column_name = 'hide_return_to_basket_btn_as_soon_as_payment_line_exists'
    ) THEN
        ALTER TABLE pos_config RENAME COLUMN hide_return_to_basket_btn_as_soon_as_payment_line_exists TO pos_payment_terminal_hide_back_btn;
    END IF;
END $$;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'account_journal' 
          AND column_name = 'pos_terminal_payment_mode'
    ) THEN
        ALTER TABLE account_journal RENAME COLUMN pos_terminal_payment_mode TO oca_payment_terminal_mode;
    END IF;
END $$;

-- pos_payment_terminal_return --
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pos_config' 
          AND column_name = 'iface_payment_terminal_return'
    ) THEN
        ALTER TABLE pos_config RENAME COLUMN iface_payment_terminal_return TO oca_payment_terminal_return;
    END IF;
END $$;

-- pos_transfer_account --
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pos_config' 
          AND column_name = 'transfer_account_id'
    ) THEN
        ALTER TABLE pos_config RENAME COLUMN transfer_account_id TO suspense_account_id;
    END IF;
END $$;

-- pos_automatic_cashdrawer --
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'account_journal' 
          AND column_name = 'iface_automatic_cashdrawer'
    ) THEN
        ALTER TABLE account_journal RENAME COLUMN iface_automatic_cashdrawer TO oca_iface_automatic_cashdrawer;
    END IF;
END $$;

-- pos_payment_change_account
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'account_journal' 
          AND column_name = 'change_account_id'
    ) THEN
        ALTER TABLE account_journal RENAME COLUMN change_account_id TO oca_change_account_id;
    END IF;
END $$;


-- pos_payment_credit
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'account_journal' 
          AND column_name = 'is_credit'
    ) THEN
        ALTER TABLE account_journal RENAME COLUMN is_credit TO oca_is_credit;
    END IF;
END $$;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'pos_config' 
          AND column_name = 'auto_apply_credit_amount'
    ) THEN
        ALTER TABLE pos_config RENAME COLUMN auto_apply_credit_amount TO oca_auto_apply_credit_amount;
    END IF;
END $$;
