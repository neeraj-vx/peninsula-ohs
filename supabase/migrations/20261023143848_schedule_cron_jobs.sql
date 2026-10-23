-- =============================================================
-- D10: functions documented as "daily cron" were never scheduled;
-- check-training-expiry and check-hiring-compliance-alerts were
-- declared in migrations but never registered. cron.schedule with
-- an existing job name updates that job, so this is re-runnable.
-- All times UTC. Dry-run of every command passed on 2026-10-23.
-- =============================================================

-- Status sweeps, shortly after midnight
SELECT cron.schedule('mark-overdue-actions',            '5 0 * * *',    'SELECT mark_overdue_actions()');
SELECT cron.schedule('mark-overdue-capas',              '6 0 * * *',    'SELECT mark_overdue_capas()');
SELECT cron.schedule('mark-overdue-inspections',        '7 0 * * *',    'SELECT mark_overdue_inspections()');
SELECT cron.schedule('mark-overdue-asset-inspections',  '8 0 * * *',    'SELECT mark_overdue_asset_inspections()');
SELECT cron.schedule('mark-overdue-risk-reviews',       '9 0 * * *',    'SELECT mark_overdue_risk_reviews()');
SELECT cron.schedule('mark-overdue-health-checks',      '10 0 * * *',   'SELECT mark_overdue_health_checks()');
SELECT cron.schedule('refresh-training-statuses',       '11 0 * * *',   'SELECT refresh_training_record_statuses()');
SELECT cron.schedule('mark-expired-permits',            '*/15 * * * *', 'SELECT mark_expired_permits()');

-- Work generation and escalation
SELECT cron.schedule('create-scheduled-inspections',    '0 1 * * *',    'SELECT create_due_scheduled_inspections()');
SELECT cron.schedule('process-escalations',             '*/5 * * * *',  'SELECT process_due_escalations()');

-- Metrics
SELECT cron.schedule('compute-kpi-snapshots',           '0 2 * * *',    'SELECT compute_all_kpi_snapshots()');

-- Daily alerts (de-duplicated inside the functions)
SELECT cron.schedule('check-training-expiry',           '0 8 * * *',    'SELECT check_expiring_training()');
SELECT cron.schedule('check-hiring-compliance-alerts',  '0 9 * * *',    'SELECT check_hiring_compliance_alerts()');

-- Weekly reminders (Mondays)
SELECT cron.schedule('notify-sds-review-due',           '0 7 * * 1',    'SELECT notify_sds_review_due()');
SELECT cron.schedule('notify-upcoming-health-checks',   '5 7 * * 1',    'SELECT notify_upcoming_health_checks()');
SELECT cron.schedule('notify-expiring-documents',       '10 7 * * 1',   'SELECT notify_expiring_documents()');
SELECT cron.schedule('notify-env-reporting-due',        '15 7 * * 1',   'SELECT notify_env_reporting_due()');
