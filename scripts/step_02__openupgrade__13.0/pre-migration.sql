

UPDATE ir_cron SET active = FALSE;
DELETE FROM ir_mail_server;
DELETE FROM fetchmail_server;
DELETE FROM ir_attachment WHERE url LIKE '/web/content/%';
DELETE FROM queue_job;
