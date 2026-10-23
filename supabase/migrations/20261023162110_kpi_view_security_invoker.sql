-- Advisor 0010: v_kpi_current ran with its owner's rights, bypassing
-- RLS on kpi_snapshots, so any signed-in user saw every tenant's KPIs.
ALTER VIEW public.v_kpi_current SET (security_invoker = true);
