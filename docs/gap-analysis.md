# Gap Analysis — EXXIO → Peninsula Canada HR & OHS Platform

**Status:** Draft for approval (Step 1 + Step 2 proposals). No migrations or code have been changed.
**Snapshot:** `main` @ `4ed5356`, 148 migrations (`20260604000001` … `20260612000006`), 2026-10-23.
**Live check:** Supabase project `oygrhongvmaxphzvmpcd`, read-only queries, 2026-10-23. See §5.1. **The live database differs materially from the repo.**

## 0. Caveats

- **Spec source.** The "Dev Build Spec v1" was not available. This analysis uses `Peninsula_Canada_OHS_Platform_Overview.docx.md` (March 2026, Draft / Internal Review) as the target. That document is a scope overview, not a build spec: it has no data model, no acceptance criteria, no §4.2 role table, no §5.2 rules engine and no Appendix B. References in the brief are remapped as follows:

  | Brief reference | Section of the Overview used |
  |---|---|
  | §4–9 feature areas | §3.1 OHS Core, §3.2 Training, §3.3 Hiring, §3.4 Background Checks, §5 Differentiators, §6 Tech Stack |
  | §4.2 roles | §6 "Supabase Auth with multi-role access (Admin, Manager, Employee)" |
  | §5.2 rules engine | §5 "Province-Specific Content … compliance rules" + Phase 2 "Province-specific compliance content and rules" |
  | §6.9 training | §3.2 Employee Training & Compliance |
  | Appendix B | Not present — see Open Questions |

- **Verified against migrations, then against the live database.** §1–4 were written from the migration files. §5 has been re-checked against the live project (2026-10-23), and §5.1 records where live differs. The biggest differences: **RLS is disabled on every OHS table**, 30 migrations exist only in the live database, and live migration versions from `20260606*` onward do not match the repo filenames.
- **`INCOMPLETE_FEATURES.md` is stale.** Training, toolbox talks, contractors, emergency response, PPE issuance, JSA and fatigue rules have all been built since it was written (migrations `20260606*`, `20260608*`, `20260610*`). "Modules 12 and 13 were never built" is true for the *numbering* only. Training exists as unnumbered migrations.

## Legend

| Status | Meaning |
|---|---|
| **Exists** | Covered by current tables/functions/screens |
| **Partial** | Some coverage; gap described |
| **Missing** | Must be built |
| **Conflict** | Spec and code (or code and code) disagree; needs a decision |

---

## 1. Feature mapping

### 1.1 OHS Compliance — Overview §3.1

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Risk assessment with ready-to-use, industry-customisable templates | **Partial** | `risks`, `risk_controls`, `risk_reviews`, `risk_categories`, 5×5 matrix (`risk_likelihood_levels`, `risk_consequence_levels`, `risk_matrix_thresholds`), `compute_risk_levels`, `mark_overdue_risk_reviews`. Templates: `risks.is_template`, `template_industry` (`20260610000003`). UI `/risks`, `/risks/templates` | Template seed `20260610000004_risk_template_seed.sql` inserts columns that do not exist on `risks` (see §5). Industries cover general, construction, food service and retail only. There are no manufacturing or office templates. |
| Real-time incident and injury reporting with alerts | **Exists** | `incidents`, `incident_people_involved`, `incident_medical`, `incident_witnesses`, `incident_evidence`, `investigations`, `rca_*`, `incident_capa`, `regulatory_submissions`; `notify_on_incident_insert`, `notify_on_capa_insert`, `auto_assign_incident`. UI `/incidents`, `/investigations` | Alerts depend on `notification_rules`, and none are seeded (§5). `regulatory_due_date` is a plain date, with no business-day or provincial reporting-deadline logic. There is no WSIB Form 7 / WorkSafeBC Form 7 reporting mapping. |
| Hazardous substances following WHMIS | **Partial** | `chemicals`, `chemical_sds` (16-section, versioned, review dates), `chemical_hazard_classes` (GHS H-codes and pictograms), `chemical_inventory`, `chemical_compatibility_rules`, `notify_sds_review_due`. UI `/chemicals` | The model is GHS-based, which WHMIS 2015 aligns with. Missing are WHMIS-specific items: supplier/workplace label tracking, the 3-year SDS currency check, the worker-education link to WHMIS training, and WHMIS hazard-class labels. |
| Safety task assignment and tracking | **Exists** | `actions` (polymorphic source), `action_assignments`, `action_extensions`, `action_comments`, `action_evidence`, `get_my_actions`, `mark_overdue_actions`. UI `/actions` | `mark_overdue_actions` is never scheduled in pg_cron (§5). |
| Mobile app for field workers | **Partial** | PWA shell: `public/sw.js`, `app/offline/page.tsx` | There is no offline write queue, and no mobile-optimised flows for incident, checklist or toolbox capture. |
| Secure document storage with e-signature | **Partial** | `documents`, `document_versions`, `document_types`, `document_review_workflows*`, `document_acknowledgements` (`signature_image_url`, `signer_name`), `organisations.required_signature_method`; storage bucket `org-documents` (`20260608000011_storage_rls.sql`). UI `/documents` | E-signature is native only (drawn or typed). There is no DocuSign/HelloSign integration (§6 of the spec). The signature audit trail has no hash, IP or timestamp certificate. |
| (Implied) inspections, audits, permits, LOTO, JSA, PPE, emergency, contractors, environment, health, fatigue | **Exists** | Modules 6, 8, 9, 11, 15, 16, 18, 19, 23, 24, plus `module_contractors`, `module_emergency` | Beyond the spec's MVP scope. Several have defects (§5) and AU terminology (§6). |

### 1.2 Employee Training & Compliance — Overview §3.2

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Built-in LMS: assign courses and track completion | **Partial** | `training_courses`, `training_course_modules` (document/video/quiz/checklist/external_url/reading), `training_module_completions`, `training_records`; actions `createCourse`, `addCourseModule`, `completeModule`, `createTrainingRecord`. UI `/training/courses`, `/training/records`, course player at `/training/courses/[id]/modules/[moduleId]` | There is **no course assignment entity**: nothing records "worker X must complete course Y by date Z". Assignment exists only for inductions (`induction_completions`, `assignInduction`). Quiz scoring and pass marks are not persisted. A `training_records` row is not created automatically when all modules are complete. |
| Pre-built courses (workplace safety, WHMIS, harassment, emergency) | **Partial** | System courses seeded in `20260610000007_training_course_seed.sql` (organisation_id NULL): WHMIS-2015, HVP-101, EVAC-101, MMH-101, WAH-101 | Seed text mixes AU and CA terms ("Provincial WHS legislation"). Missing: Ontario Worker / Supervisor Health & Safety Awareness, first aid, forklift. There is no "sample content — legal review required" marker. |
| Custom courses | **Exists** | `training_courses.organisation_id` set; CourseForm | — |
| Province-specific content | **Partial** | `training_courses.applicable_provinces`, `organisations.province`; "Jurisdiction Compliance" panel on `app/(platform)/training/page.tsx` | Province applies only as a course filter. Requirements are not driven by site province (`sites` has no province column). |
| Automated reminders before certifications expire | **Partial** | `update_training_record_status()` trigger (current / expiring_soon / expired; 60-day window); `check_expiring_training()` pg_cron 08:00 UTC; template `training.expiring_soon` | Status is only recomputed on write, so it goes stale. The cron re-notifies the same records every day (no de-duplication). The 60-day window is hardcoded. `expiry_date` is entered manually and not derived from `validity_period_months`. There are no `training.completed`, `training.expired` or `competency.expired` webhooks. |
| Completion certificates for audits | **Exists** | `components/training/CertificateButton.tsx` (jsPDF, client-side); `training_records.certificate_number`, `certificate_file_url` | Certificates are not stored or immutable server-side. There is no verification code. |
| (Brief) Toolbox talks as a training type | **Conflict** | Separate module: `toolbox_talk_categories`, `toolbox_talk_templates`, `toolbox_talk_template_points`, `toolbox_talk_deliveries`, `toolbox_talk_attendees`, `toolbox_talk_schedules`. UI `/toolbox` | Attendance does not produce training records. Agreed approach: keep the tables and link them into training (see §7). |
| (Brief) Competencies / external certs | **Missing** | Closest: `worker_licences` + `worker_licence_alerts` (BGC module, `20260612000001`) | There are no `competency_types` or `worker_competencies` tables. |
| (Brief) Course versioning and refreshers | **Missing** | `training_courses` has no version | — |
| (Brief) Auto-assign by role / site / province / activity | **Partial** | `training_needs_matrix` (role → course, `is_mandatory`) | Role is the only dimension. `UNIQUE(role_id, course_id)` lacks `organisation_id` (§5). It has no due-days or recurrence, and nothing generates assignments from it. |
| (Brief) Training compliance rate KPI | **Missing** | `kpi_definitions` has 8 incident/inspection KPIs | — |

### 1.3 Hiring Compliance & Workflows — Overview §3.3

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Step-by-step hiring guides by province | **Exists** | `hires` (8-step wizard, `compliance_province`), `HiringWizard.tsx`, `/hiring/new` | Guide content is in components, not versioned data. |
| Province-aware template library (offer letters, contracts, NDAs, policies) | **Exists** | `hr_document_templates` (`applicable_provinces`, `province_clauses` jsonb, `variable_definitions`, `is_system_template`), `/hiring/templates` | `version` is free text, so templates are not version-locked when used on a hire. No `required_clause` rules are seeded. |
| Structured onboarding checklists | **Exists** | `onboarding_templates`, `onboarding_template_tasks` (links to `documents` / `training_courses`, `due_days_from_start`), `onboarding_assignments`, `onboarding_task_completions` | `due_days_from_start` is in calendar days. A `complete_training` task does not create a training assignment. |
| Compliance checks that flag missed steps | **Partial** | `employment_jurisdiction_rules` (province, org override, effective-dated); `runComplianceCheck` in `app/actions/hiring.ts:200` | The five checks are **hardcoded in TypeScript** (min wage, probation, fixed-term, required docs, vacation pay). Only ON/BC/AB/QC are seeded. The `stat_holiday_pay_pct` rule key actually holds vacation-pay %. This is the main candidate for migrating to the rules engine (§8). |
| E-signature on hiring docs | **Exists** | `hire_documents` (candidate/employer `signed_at` + signature URLs), `recordDocumentSignature` | Native only (see 1.1). |
| (Implied) Reference numbers | **Partial** | `generate_hire_number` (HIR-NNNN via MAX+1) | Race-prone. Does not use `next_reference_number`. |

### 1.4 Background Checks — Overview §3.4

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Identity, criminal, education, employment, reference checks | **Exists** | `bgc_check_type` enum, `bgc_packages`, `bgc_orders`, `bgc_results`, `bgc_result_raw`, `bgc_reference_*`; public token pages `/bgc-consent/[token]`, `/bgc-reference/[token]` | Provider adapters are stubbed (`bgc_providers`, `/api/background-checks/webhook`). There is no live Canadian provider. |
| Consent and adverse action | **Exists** | `bgc_consent_templates` (versioned, locked), `bgc_consent_records` (append-only), `bgc_adverse_action_notices`, `bgc_disputes`, `bgc_adjudications`; `lib/background-checks/adverse-action.ts` | The dispute window uses a hardcoded **federal 2026-only** holiday list in TypeScript (`CANADIAN_HOLIDAYS_2026`). It needs provincial holidays from data (§5). |
| Periodic re-verification | **Exists** | `bgc_reverification_schedules`, `bgc_reverification_events`, cron `bgc-reverification-due` | — |
| Licence / certification renewal tracking | **Exists** (overlaps training) | `worker_licences`, `worker_licence_alerts`, cron `bgc-licence-expiry-alerts` | Overlaps the planned `worker_competencies` and must be reconciled (§7). |
| Role-based check requirements | **Exists** | `bgc_role_requirements` | Free-text positions, not linked to `roles`. |

### 1.5 Differentiators — Overview §5

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Analytics dashboard: compliance health score, training completion, incident trends, risk areas | **Partial** | `kpi_definitions` (8), `kpi_snapshots`, `kpi_targets`, `report_definitions`, `report_schedules`, `dashboard_widget_configs`, `compute_kpi_snapshot`. UI `/dashboard`, `/reports`, `/reports/builder` | `compute_kpi_snapshot` references columns that don't exist (§5), so TRIFR/LTIFR/severity/near-miss cannot compute. `compute_all_kpi_snapshots` is not scheduled. There is **no compliance health score** and no training KPI. |
| Province-specific content and rules | **Partial** | `applicable_provinces` on `risks`, `documents`, `training_courses`, `hr_document_templates`; `employment_jurisdiction_rules` | There is no general rules engine. `compliance_obligations` has no province or jurisdiction field. `regulatory_bodies` is seeded with AU/US bodies only. See §8. |
| All-in-one | **Exists** | — | — |

### 1.6 Tech Stack / Platform — Overview §6

| Spec item | Status | Existing coverage | Gap |
|---|---|---|---|
| Next.js + Supabase + Vercel | **Exists** | — | — |
| Multi-role auth | **Conflict** | See §2 | — |
| Multi-tenancy | **Exists** | `organisation_id` on every tenant table; `get_my_organisation_id()`; subdomains (`20260608000010_multi_tenancy.sql`); super-admin console `/admin` | `lib/supabase/get-org-id.ts` falls back to the first org via the service role when no user is present. This is a dev bypass that must not ship. |
| Storage | **Exists** | `org-documents` bucket, `{org_id}/…` path RLS | — |
| Integrations (BGC APIs, e-sign, email) | **Partial** | `webhook_endpoints` / `webhook_event_types` / `queue_webhook_deliveries`, API keys, `integration_types` (HRIS, SSO, BI, SMTP) | No e-sign provider. Email delivery via `notification_deliveries` was not verified end-to-end. |
| Audit trail | **Partial** | `audit_logs` (module-1 tables only), `row_versions` (core OHS tables) | Training, hiring, BGC, compliance and contractors have **no audit triggers**. |

---

## 2. Roles

### 2.1 Existing roles

Roles are rows in `roles`, not an enum. System roles are seeded in `20260604000004_module1_seed.sql:13` and `20260612000005_bgc_seed.sql:236`. Orgs may add custom roles (`roles.organisation_id` not null).

| Existing role (exact name) | Helper | Scope today |
|---|---|---|
| `System Admin` | `is_system_admin()` | Whole org |
| `Executive` | `is_executive()` | Whole org, mostly read |
| `HSE Officer` | `is_hse_officer()` (~330 policy references) | Whole org |
| `Supervisor` | `is_supervisor()` | Assigned sites (`get_my_site_ids()`) |
| `Worker` | none (fallback) | Assigned sites; own records |
| `Background Check Reviewer` | `is_bgc_reviewer()` | BGC adjudication |
| Platform super admin | separate `super_admins` table + `exxio_sa_token` cookie | Cross-org, service role |

The RLS helpers are in `20260604000003_module1_rls.sql`: `get_my_organisation_id()`, `user_has_role(text)`, `user_has_permission(module, action)`, `is_*()` and `get_my_site_ids()`. `20260604000007_module2_rls.sql` adds `can_access_site(uuid)` and `get_accessible_site_ids()`.

### 2.2 Mapping to spec roles (Overview §6: Admin, Manager, Employee)

| Spec role | Proposed mapping | Notes |
|---|---|---|
| Admin | `System Admin` | 1:1 |
| Manager | `HSE Officer` + `Supervisor` + `Executive` | **Conflict.** The spec has one manager tier; the code has three with different scope (org-wide vs site). Proposal: keep all three, and present them in the UI as "Manager — Health & Safety", "Manager — Site Supervisor" and "Manager — Executive (read-only)". |
| Employee | `Worker` | 1:1 |
| — | `Background Check Reviewer` | No spec equivalent. Keep it as an add-on role. |

### 2.3 Role-enforcement conflicts

- **No app-side role gating.** `middleware.ts` only checks for an authenticated user. Every nav item in `components/shell/AppShell.tsx` is shown to every role. All enforcement is RLS.
- **Two RLS styles coexist.** Modules 1–17, 25, hiring and BGC use `get_my_organisation_id()` + role/site helpers. Training, toolbox, contractors, emergency, JSA, PPE and `user_invitations` use `organisation_id IN (SELECT organisation_id FROM user_profiles WHERE id = auth.uid())` with `FOR ALL` and **no role checks**, so any worker can edit or delete any training record in the org.
- **Cross-org leak:** `public_read_tmc` on `training_module_completions` is `FOR SELECT USING (true)` (`20260610000008_module_completions.sql:13`). Any user, including anon, can read every org's completions.

---

## 3. Conflicts summary

| # | Conflict | Between | Proposed resolution (needs approval) |
|---|---|---|---|
| C1 | "Modules 12/13 never built" vs existing training migrations `20260608000001–03`, `20260610000005–08` | Brief vs code | Extend the existing training tables (already agreed). New migrations continue the date-based naming with a `module12_*` / `module13_*` suffix so the numbering gap is filled. |
| C2 | Toolbox talks inside training vs separate `toolbox_talk_*` module | Brief / Incomplete Features vs code | Keep the toolbox tables. Add a `training_type = 'toolbox_talk'` course type and link `toolbox_talk_deliveries` → `training_courses`, with attendees producing `training_records` (agreed: extend, don't move). |
| C3 | 3 spec roles vs 6 code roles | Spec vs code | §2.2 mapping; no role renames. |
| C4 | `worker_competencies` (Incomplete Features) vs existing `worker_licences` (BGC) | Code vs plan | See §7. Decision needed. |
| C5 | `training_requirements` (Incomplete Features) vs existing `training_needs_matrix` | Code vs plan | Extend `training_needs_matrix` into data-driven assignment rules (§7). |
| C6 | E-sign via DocuSign/HelloSign (spec §6) vs native drawn/typed signature | Spec vs code | Keep native for MVP; provider integration stays a Phase 2 item. Decision needed. |
| C7 | `organisation` (British spelling) everywhere vs Canadian "organization" | Localisation | Keep identifiers; change UI copy only (17 visible labels). |
| C8 | Two RLS styles (§2.3) | Code vs code | New tables use the module-1 style (`get_my_organisation_id()` + role helpers). Tightening the old org-only policies is proposed as a separate fix migration. |
| C9 | Hiring compliance checks hardcoded in TS (`runComplianceCheck`) vs "legal rules in versioned data" convention | Brief vs code | Move them to the rules engine in Step 4; do not change them in Step 3. |
| C10 | KPI codes `TRIFR` / `LTIFR` (AU/UK convention) vs Canadian TRIR / LTIR (200,000-hour base) | Localisation | The formula base differs (1,000,000 vs 200,000 hours), so this is more than a label. Decision needed. |

---

## 4. Rules / obligations — what exists (input to Step 4)

| Existing | What it does | Limitation vs a rules engine |
|---|---|---|
| `employment_jurisdiction_rules` (`20260611000001`) | Province-keyed, org-overridable, effective-dated values (`rule_type`, `rule_key`, `rule_value`, `rule_value_numeric`) | Values only; the logic lives in TS. No version table, no publish workflow, hiring only. |
| `compliance_obligation_types`, `compliance_obligations`, `compliance_tasks` (`20260606000009`) | Org obligation register with frequency and `next_due_date` | No province, no link to a legal source, no rule that creates obligations, no task generator, no score. |
| `regulatory_bodies`, `regulatory_standards`, `regulatory_requirements` (module 21) | Reference library | Seeded with AU/US bodies. Free-text jurisdiction. |
| `notification_rules` (module 3) | Event → recipient routing with conditions jsonb | Notification routing only. |
| `fatigue_rule_sets`, `fatigue_rules` (module 24) | Threshold config | No evaluator. |
| `bgc_role_requirements` | Position → required check | BGC only. |

**Conclusion:** a general rules engine (rules, rule versions, applicability by province/industry/headcount/activity, generated obligations, compliance score) is **Missing**. The design is deferred to Step 4. The Step 3 training assignment rules will be shaped so they can become a rule type later.

---

## 5. Defects found during analysis

These were found while reading the migrations. They are listed because several **block Step 3** (training inserts fail today). All fixes will be **new migrations**; applied migrations will not be edited.

| # | Severity | Defect | Evidence | Blocks Step 3? |
|---|---|---|---|---|
| D1 | ~~High~~ **Fixed live, missing from repo** | `reference_counters` has columns `(entity_type, organisation_id, year, last_number)`, but 9 generators insert `(organisation_id, sequence_key, last_value)`. These run as BEFORE INSERT triggers, so inserts fail for TRN, TBX, JSA, LOTO, LAUTH, COMP, SPK, DRL and ERP. **Live:** columns `sequence_key`/`last_value` were added, the PK is now `(entity_type, organisation_id, year, sequence_key)`, and all generators were rewritten (live-only migrations `20260609170143` … `20260609173051`). 21 counter rows exist. A clean replay of the repo still fails. Residual issue: sequence-key rows use `year = 0`, so TRN/JSA/… numbers never reset per year even though they print the current year. | Table: `20260605000013_module4_schema.sql:69`. Broken use: `20260608000002_module_training_rls.sql:39`. Working helper: `next_reference_number()` in `20260605000014_module4_triggers.sql:48` | Repo only |
| D2 | **High** (moot live: see D18) | Cross-org read: `public_read_tmc … FOR SELECT USING (true)`. **Live:** the policy exists, but RLS is disabled on `training_module_completions`, so no policy applies at all (0 rows today). | `20260610000008_module_completions.sql:13` | Yes |
| D3 | **High** | `org_risks` `FOR ALL USING (organisation_id IS NULL OR …)`. Policies are OR-combined, so any org member can update or delete any risk. Because the USING clause doubles as WITH CHECK, any user can also modify **system templates** (org NULL) for all tenants. | `20260610000003_risk_templates.sql:8-12` | No |
| D4 | High — **confirmed live** | `compute_kpi_snapshot` reads `incidents.occurred_at`, `incident_medical.days_lost` and `treatment_type`. The real columns are `incident_date`, `lost_time_days` and `treatment_provided`. The live function body is unchanged, so TRIFR, LTIFR, severity and near-miss raise at runtime. | `20260605000058_module17_triggers.sql:61,80,92` | Yes (the training KPI reuses this function) |
| D5 | ~~Medium~~ **Fixed live** | The risk template seed inserts non-existent columns and writes to generated score columns. **Live:** the applied SQL uses the real columns (`likelihood_score`, `consequence_score`, …). The repo file was the broken one, and the 2026-10-23 rebuild replaced it. | `20260610000004_risk_template_seed.sql` | No |
| D6 | ~~Medium~~ **Fixed live** | `ppe_types` is created in module 11 (no `category`). Module 23 uses `CREATE TABLE IF NOT EXISTS` with `category NOT NULL`, so it is skipped, and the module 23 seed fails. **Live:** the applied seed adds `category`/`standard_reference` via `ALTER TABLE … ADD COLUMN IF NOT EXISTS` and updates by `code`. The repo now carries the live SQL. | `20260606000021_module23_schema.sql:2` | No |
| D7 | Medium — **confirmed live** | No `notification_rules` rows are seeded, so `create_notification()` delivers nothing until an org configures rules. **Live:** 0 rules across 3 orgs, against 62 notification templates. | grep: no `INSERT INTO notification_rules` | Yes (training notifications) |
| D8 | Medium — **confirmed live** | `training_needs_matrix UNIQUE(role_id, course_id)` has no `organisation_id`, so two orgs cannot map the same system role to the same system course. Live constraint: `training_needs_matrix_role_id_course_id_key`. `organisation_id` is NOT NULL, so `UNIQUE(organisation_id, role_id, course_id)` is a safe replacement. | `20260608000001_module_training_schema.sql:26` | Yes |
| D9 | Medium | Training status is computed only on write and goes stale. `check_expiring_training` re-sends daily with no de-duplication. | `20260608000002`, `20260610000005` | Yes |
| D10 | Medium | Functions documented as "daily cron" are never scheduled: `mark_overdue_capas`, `mark_overdue_actions`, `mark_overdue_inspections`, `create_scheduled_inspection`, `mark_overdue_risk_reviews`, `mark_expired_permits`, `compute_all_kpi_snapshots`, `fire_escalation_step` and others. The repo declares 4 pg_cron jobs. **Live has only 2** (`bgc-licence-expiry-alerts` 08:00, `bgc-reverification-due` 08:30). `check-training-expiry` is missing because its guard skipped scheduling (pg_cron was not yet enabled). The live copy of `hiring_compliance_notifications` has no `cron.schedule` at all, so the repo file was edited after it was applied. All 10 target functions do exist live. | grep `cron.schedule`; `select * from cron.job` | Partly |
| D11 | Medium | No business-day or statutory-holiday logic in SQL. The only implementation is a hardcoded federal 2026 list in TS. | `lib/background-checks/adverse-action.ts:1` | Yes (convention) |
| D12 | Medium | Org-only `FOR ALL` RLS with no role checks on the training, toolbox, contractor, emergency, JSA and PPE tables | `20260608000002`, `…09`, `…05`, `…07` | Yes |
| D13 | Low | `generate_hire_number` and `generate_bgc_package_number` use MAX+1 / COUNT+1 (race-prone) | `20260611000010_hiring_workflow_triggers.sql`, `20260612000001_bgc_schema.sql` | No |
| D14 | Low | `get-org-id.ts` service-role fallback to the first org | `lib/supabase/get-org-id.ts` | No (but must not ship) |
| D15 | Low | No audit triggers on the training, hiring, BGC, compliance and contractor tables | — | Yes (convention) |
| D16 | — | No test framework (no vitest/jest/pgTAP; `package.json` has only dev/build/start/lint) | `package.json` | Yes (tests are required) |
| D17 | Low | `docs/email-confirmation-dev-workaround.md` references migration `20260605000065_auto_confirm_emails_no_smtp.sql`; that number is actually `_bootstrap_organisation.sql` | — | No |

| D18 | **Critical** (live) | **RLS is disabled on all 253 OHS/HR/BGC tables.** Live-only migration `20260609195201_disable_rls_all_tables` runs `ALTER TABLE … DISABLE ROW LEVEL SECURITY` over every `public` table. `anon` holds SELECT on all 253 of them, so the public anon key can read every tenant's incidents, medical records, health profiles, hires and BGC packages over PostgREST. The only tables with RLS on are the 115 `emr_*`/`pms_*`/`wfm_*` tables, which were created later. Advisors: `rls_disabled_in_public` ×253, `policy_exists_rls_disabled` ×246. | `supabase_migrations.schema_migrations`; `pg_tables.rowsecurity` | **Yes — blocks everything** |
| D19 | **Critical** (live) | `cleanup_demo_org(p_org_name)` is SECURITY DEFINER, sets `session_replication_role = replica` and deletes every row of the named org. It is **executable by `anon` and `authenticated`**, so anyone holding the anon key can wipe any tenant by name with `rpc('cleanup_demo_org')`. Only `scripts/seed-demo.mjs` (service role) needs it. Also: 115 SECURITY DEFINER functions are anon-executable (advisor 0028), including `bootstrap_organisation` and `create_notification`. | live-only `20260609171906` … `20260609173533` | Yes |
| D20 | High — **repo rebuilt 2026-10-23** | **Migration history drift.** (a) 30 migrations exist only live: reference-counter fixes, `cleanup_demo_org` ×4, `fix_create_notification_select_column`, `disable_rls_all_tables`, 4 × documents column fixes, and the EMR/PMS/WFM schemas. (b) From `20260606*` on, live versions are apply timestamps (e.g. `20260606185107`) whose *names* are the repo filenames (`20260606000001_module18_schema`), so `supabase db push` would treat ~80 repo files as unapplied. (c) At least one applied migration (`hiring_compliance_notifications`) differs from its repo file. As a result, the repo cannot rebuild production. **Done:** `supabase/migrations/` now holds exactly the 179 live rows, as `<live version>_<live name>.sql`, written from `schema_migrations.statements`. 134 match the old repo files, 14 differ (D5, D6, `hiring_compliance_notifications`, `module3_seed`, where the repo had the EXXIO rebrand text but live says "Peninsula OHS", plus formatting and seed values in the hiring/BGC files), and 31 were live-only. Replay is **not yet verified**: there is no Docker for a local `db reset`, so it needs a Supabase branch. | `list_migrations` vs `supabase/migrations/` | **Yes** (no reproducible test DB) |
| D21 | **Decided: drop** | **Foreign product schemas in the same project:** 45 `emr_*` (hospital EMR), 24 `pms_*` (property, `state DEFAULT 'NSW'`, `Australia/Sydney`) and 46 `wfm_*` tables. None of them are in the repo, and they FK into `organisations`/`sites`. Migration `20261023190100_drop_emr_pms_wfm.sql` is written but **not applied**: the apply was declined at the destructive-statement confirmation on 2026-10-23. Its filename version is a placeholder; rename it to the recorded version once it's applied. Nothing outside these tables depends on them; only EMR seed lookups hold rows. | live-only `20260610090324` … `20260610210957` | No, but they will be swept into any bulk RLS/grant change |
| D22 | Low | `scripts/schema_export.sql` / `peninsula_schema.json` are not trustworthy as a baseline: they predate the live-only migrations. | — | No |

**Recommendation (revised after the live check):** D18 and D19 are production data-exposure issues. Fix them first, independently of Peninsula feature work. Next, make the repo reproduce production (D20), so tests run against the same schema as prod. Then apply the original fix set (D2, D3, D4, D7, D8, D10, D12). D1 needs only to be captured in the repo. See §5.2.

### 5.1 Live vs repo — verification summary (2026-10-23)

| Item | Repo says | Live shows | Doc change |
|---|---|---|---|
| Migrations | 148 files | 179 rows; 30 live-only; versions renamed from `20260606*` | D20 added |
| D1 `reference_counters` | broken | fixed (6 cols, 4-col PK, generators rewritten) | D1 → repo-only |
| D2 `public_read_tmc` | `USING (true)` | policy present, RLS off on table | D2 → moot, see D18 |
| D3 `org_risks` | `FOR ALL USING (org IS NULL OR …)` | identical (but RLS off) | none |
| D4 KPI columns | wrong columns | unchanged, still wrong | confirmed |
| D7 notification rules | none seeded | 0 rows / 62 templates | confirmed |
| D8 needs-matrix unique | `(role_id, course_id)` | same | confirmed |
| pg_cron | 4 jobs declared | 2 jobs (BGC only); pg_cron 1.6.4 installed | D10 updated |
| RLS | enabled per module | disabled on 253/368 public tables | D18 added |
| Privileged RPCs | — | `cleanup_demo_org` anon-executable | D19 added |
| Other schemas | — | `emr_*`, `pms_*`, `wfm_*` (115 tables) | D21 added |

### 5.2 Proposed foundation plan — Step 1 (test harness) and Step 2 (fix migrations)

Nothing below has been applied. Each Step 2 migration is applied only after explicit approval, first to a Supabase branch or local stack, then to production.

**Step 0 — production hotfix: APPLIED 2026-10-23 as `20261023133549_security_hotfix_revoke_anon`.** Verified after applying: anon has 0 table grants in `public`; anon can run only the `unaccent` extension functions; `cleanup_demo_org` is service-role only; `authenticated` lost no function access. A single migration `…_security_hotfix.sql`:
- `REVOKE EXECUTE ON FUNCTION cleanup_demo_org(text) FROM public, anon, authenticated;` The seed script uses the service role, so it keeps working.
- Do **not** bulk re-enable RLS here. `disable_rls_all_tables` was added to unblock the app (the likely cause is policy and `get_my_organisation_id()` failures, which pair with D14's service-role fallback). Turning RLS back on blind would take the app down.
- Revoke **all** anon access in `public`: tables, sequences, and EXECUTE on postgres-owned functions (via `PUBLIC`, then granted back to `authenticated` and `service_role`), plus the default privileges for new objects. Checked: the app never queries as anon. `/login` and `/register` run no table queries, and middleware redirects every unauthenticated platform request. The auth triggers are SECURITY DEFINER functions owned by `postgres`, so they're unaffected. The one direct anon-key use, `bgc-reference/[token]/ReferenceQuestionnaireForm.tsx` (client-side insert), is already unreachable for logged-out referees, because middleware also redirects `/bgc-*`. That's a separate bug: the BGC public routes need adding to the middleware allow-list, and the form should move to a server action.
- Limitation: `authenticated` still has full table access with RLS off, and `/register` is open. Any self-registered user can still read every tenant. Only Step 2.7 closes that.

**Step 1 — test harness (no DB changes).**
1. **Make the repo reproduce prod (D20).** Recommended approach: `supabase migration fetch` (or a script that writes `supabase_migrations.schema_migrations.statements`). This rewrites `supabase/migrations/` to exactly the 179 live rows, using live versions and live SQL. Diff each replaced file against its old repo copy and record every drift in this doc. The EMR/PMS/WFM migrations go in too, because prod has them (D21 decides their future). Alternative: a single `supabase db dump` baseline plus `migration repair`. That is simpler but loses history; recommend only if fetch fails.
2. **Local stack:** `supabase start` + `supabase db reset` must succeed from a clean state. This becomes the first CI gate.
3. **pgTAP DB tests** in `supabase/tests/*.test.sql`, run by `supabase test db`. Helpers: `tests/helpers/auth.sql` (create org A/B, users per role, `set_config('request.jwt.claims', …)` + `set role authenticated`). Initial suite: regression tests written to **fail on today's schema**:
   - `rls_enforced.test.sql`: every `public` table has `rowsecurity = true` (allow-list for intentional lookups) (D18)
   - `tenant_isolation.test.sql`: user in org A sees 0 rows of org B in training_module_completions, incidents, risks, training_records (D2, D3, D12)
   - `privileged_rpc.test.sql`: anon/authenticated cannot execute `cleanup_demo_org` (D19)
   - `kpi_snapshot.test.sql`: `compute_kpi_snapshot('trifr', …)` returns the expected value on fixture data (D4)
   - `reference_numbers.test.sql`: TRN/TBX/JSA/… inserts get sequential numbers per org (D1)
   - `training_matrix.test.sql`: two orgs map the same role/course (D8)
   - `cron_jobs.test.sql`: expected job names are present in `cron.job` (D10)
   - `notification_rules.test.sql`: a new org has the default rules after bootstrap (D7)
4. **Vitest** for TS (`lib/**`, server-action pure logic), starting with `lib/background-checks/adverse-action.ts` business days (D11). Add scripts `test`, `test:db`, `test:all` to `package.json`. Pick one package manager: both `package-lock.json` and an untracked `pnpm-lock.yaml` exist.
5. **CI** (GitHub Actions): `supabase start` → `db reset` → `test db` → `vitest run` → `next build`.

**Step 2 — fix migrations (forward-only, new files, applied after approval).**

| Order | Migration | Fixes | Notes |
|---|---|---|---|
| 2.1 | `…_fix_kpi_snapshot_columns` | D4 | `CREATE OR REPLACE` with `incident_date`, `lost_time_days`, `treatment_provided`. Map the treatment values to the actual `treatment_provided` vocabulary (check the enum/check constraint). |
| 2.2 | `…_fix_training_needs_matrix_unique` | D8 | Drop `training_needs_matrix_role_id_course_id_key`, add `UNIQUE (organisation_id, role_id, course_id)`. Safe because the old constraint is stricter. |
| 2.3 | `…_fix_reference_counter_year_reset` | D1 residual | Optional: use `year = extract(year …)` in the sequence-key generators, or keep perpetual numbering and drop the year from the prefix. Needs a decision. |
| 2.4 | `…_schedule_cron_jobs` | D10 | Idempotent `cron.unschedule`/`schedule` for `check-training-expiry`, `check-hiring-compliance-alerts`, `mark_overdue_*`, `mark_expired_permits`, `create_scheduled_inspection`, `compute_all_kpi_snapshots`, `fire_escalation_step`. Fix the D9 de-duplication first, or alerts repeat daily. |
| 2.5 | `…_seed_default_notification_rules` | D7 | Per-org default rules: inserted for the 3 existing orgs and added to `bootstrap_organisation`. `create_notification` matches `organisation_id = p_org`, so NULL-org "system" rules would not fire without changing the function. |
| 2.6 | `…_rls_policy_repair` | D2, D3, D12 | Drop `public_read_tmc`. Split `org_risks` into SELECT (org OR template) and write policies (org only, `organisation_id IS NOT NULL`). Add role checks on training/toolbox/contractor/emergency/JSA/PPE writes. |
| 2.7 | `…_reenable_rls` | D18 | `ENABLE ROW LEVEL SECURITY` on all non-`emr/pms/wfm` public tables. Ships only when the tenant-isolation suite **and** a smoke run of the app (all routes, each role) pass on a branch. Remove the D14 fallback in the same release. |
| 2.8 | `…_revoke_definer_exec` | D19 tail | Revoke anon EXECUTE on SECURITY DEFINER functions not meant for anon. Set `search_path` on the 68 functions flagged by advisor 0011. |

D5 and D6 turned out to be fixed in the live database, and Step 1.1 brought that SQL into the repo.

### 5.3 Execution status (2026-10-23)

**Applied to production** (via MCP `apply_migration`):

| Migration | Fixes |
|---|---|
| `security_hotfix_revoke_anon` | D19; anon access removed |
| `fix_kpi_snapshot_columns` | D4 |
| `fix_reference_numbering` | D1 residual (per-year counters, carried over), D13, SECURITY DEFINER counter helper (RLS prerequisite) |
| `fix_notifications_and_default_rules` | D23, D7: 60 rules per org; new orgs seeded by trigger |
| `training_status_refresh_and_alert_dedupe` | D9; batch wrappers for inspections/escalations |
| `fix_queue_webhook_deliveries_columns` | D24: every notification insert failed |
| `fix_kpi_inspection_rate_and_document_expiry` | D24 |
| `schedule_cron_jobs` | D10: 17 jobs; every command dry-run passed |

**Waiting on you:**
1. [supabase/manual/20261023_destructive_bundle.sql](../supabase/manual/20261023_destructive_bundle.sql): test-support functions, D8, the policy repair (D2, D3, D12, system courses, emergency contacts, PPE) and the D21 drop. These contain DROP/DELETE, which the MCP server auto-declines in this session. Run it in the SQL editor.
2. Then `pnpm test:integration`, then [20261023_step2_7_reenable_rls.sql](../supabase/manual/20261023_step2_7_reenable_rls.sql) (D18), then [20261023_step2_8_harden_functions.sql](../supabase/manual/20261023_step2_8_harden_functions.sql). Both are non-destructive.
3. Regenerate `supabase/migrations/` from live history (same method as Step 1.1). The 8 applied migrations above are not yet in the repo as files.

**New defects found during execution:**
- **D23 (High, fixed):** `create_notification` inserted into the non-existent `notifications.recipient_id`. It used a recipient type (`all_org_users`) that the check constraint rejects, ignored `rule.channels` and `cooldown_minutes`, and let a caller target any org.
- **D24 (High, fixed):** more column drift. `queue_webhook_deliveries` read `NEW.event_type`/`entity_type`/`entity_id`/`site_id` on `notifications`. `compute_kpi_snapshot` read `inspections.scheduled_date`. `notify_expiring_documents` read `documents.expires_at`. Hazard report, high-risk, audit, permit, investigator and CAPA notifications would have raised errors as soon as rules existed. They were fixed in the same session, minutes after the rules were seeded.
- **D25 (Medium, fixed in code):** `addBusinessDays` mixed local `getDay()` with UTC `toISOString()`, so in UTC+12/13 zones the BGC dispute window skipped the wrong days. Covered by `tests/unit/adverse-action.test.ts` across 5 timezones.
- **D26 (Medium, fixed in code):** middleware redirected `/bgc-consent/*` and `/bgc-reference/*` to `/login`, so candidates and referees could never use their links. The reference form also wrote with the anon key from the browser. It's now a token-validated server action.
- **D14 (fixed in code):** the `getOrgId` "dev bypass" (first org via service role) was removed.

**Update, same day:** you ran the bundle, Step 2.7 (RLS re-enabled on all tables) and Step 2.8 in the SQL editor. They're recorded in history as `20261023150000/150100/150200` and the SQL is in `supabase/migrations/`. The repo now matches all 191 live history rows. The first integration run then found:
- **D27 (High, bundle 2 pending):** 18 tables have a globally unique `*_number` (incidents, actions, risks, permits, audits, inspections, CAPAs, hires, BGC packages, …), but numbers are generated per organisation. The first such record in any organisation other than the one that used the number first fails with `23505`. This predates today. Fix: [20261023_destructive_bundle_2.sql](../supabase/manual/20261023_destructive_bundle_2.sql) makes uniqueness `(organisation_id, number)`.
- **D28 (High, fixed live):** `inc_select_own` used `is_involved_in_incident(id)`, which can't see the row being inserted. `createIncident`'s `.insert().select()` failed for workers and supervisors. Added `inc_select_submitter`.
- **Site scope (fixed live):** production has 0 `user_site_assignments`, so site-scoped policies hid everything from supervisors and workers. `can_access_site` now treats "no assignments" as all active org sites.
- **D29 (High, bundle 2 pending):** `speak_up_reports` accepted inserts into any org (`WITH CHECK true`), and every member could read every confidential report.
- **D30 (Critical, fixed live):** `up_update_own` had no `WITH CHECK`, so a user could set their own `organisation_id` to another tenant's and read that tenant. A BEFORE UPDATE trigger now rejects org changes and self (de)activation from user sessions.

Integration status after these fixes: `security` 8/8, `rls-smoke` 5/5 roles × all tables, `workflows` D1/D7/D8 pass. The 4 incident-based tests fail only on D27 (`incidents_incident_number_key`).

**Closed out (same day):** bundle 2 applied (D27, D29), recorded as `20261023163000`. `v_kpi_current` switched to `security_invoker` (advisor 0010; it leaked KPIs across tenants). **`pnpm test:all`: 41/41 pass**, and no test organisations or users are left behind. Security advisors went from 253 + 246 ERRORs to 0 ERRORs.

### 5.4 Follow-ups completed (2026-10-28)

| Item | Result | Migration / commit |
|---|---|---|
| **D31** | Org and role guards added to `get_record_history`, `get_record_at_version`, `get_incident_summary`, `create_audit_finding_action`, `create_inspection_action`, `promote_hazard_to_risk`, `publish_document_version`, `submit_document_for_review`, `revoke_all_user_sessions`. `log_auth_event`, `lookup_api_key`, `stamp_api_key_last_used` and `schedule_delivery_retry` are now service-role only. Reviewed and already safe: notification ack/dismiss/read, `bulk_close_actions`, `record_user_session`, `revoke_user_session`. | `20261028122846` |
| Advisor 0014 | `unaccent` moved to the `extensions` schema (nothing referenced it) | `20261028122846` |
| **D11** | `statutory_holidays` (2026–27, federal `CA` + Ontario `CA-ON`, observed dates), `is_business_day()`, `add_business_days()`. Other provinces and years still to be seeded. | `20261028124238` |
| **D15** | Audit triggers on 38 more tables. Speak-up, BGC findings and health tables are intentionally excluded (see migration header). | `20261028124526` |
| Leaked-password protection | **Not possible on the current plan.** The dashboard rejects it ("available on Pro Plans and up"). Upgrading is a billing decision. | — |
| UI simplification | Sidebar went from 15 sections / ~60 links to 8 role-filtered entries. Sub-pages are contextual, a `/tools` launcher holds the occasional modules, there's a "Report something" menu, and the home page has quick actions, my tasks, workplace numbers and an admin setup checklist. The notification bell and dashboard counts were broken and are fixed. | `f79c278` |
| Canada localisation (§6, "L" items) | en-CA dates, CAD, Canadian timezones (default Toronto), BN label for contractors, Canadian placeholders. | `df97313` |

Tests: **46/46 pass** (unit + integration incl. business days and audit-log visibility).

**Still open (each needs a decision or input from you):**
- C10: TRIR/LTIR on a 200,000-hour base (add new KPI rows, keep TRIFR/LTIFR inactive?).
- §6 "R" items: rename `contractors.abn` → `business_number`, document type code `swms` → `swp`. Both are data migrations.
- §6 "S" items: Canadian regulator / course / KPI seed data replacing the AU rows (deactivate, don't delete).
- `lib/background-checks/adverse-action.ts` still uses its own 2026 holiday list. It should call `add_business_days()` with the candidate's province, which needs the province on the BGC package.
- Steps 3–4 (training reconciliation, rules engine) need the Dev Build Spec or the open questions in §9 answered.

**Test harness:** Vitest 3.2.4. `pnpm test` runs the unit tests. `pnpm test:integration` runs `security`, `tenant-isolation`, `workflows` (D1/D4/D7/D8/D15/D23/D27–D30), `business-days` (D11) and `rls-smoke` (every role × every table) against the live project, using throwaway `zz-test-*` organisations that are removed afterwards.

---

## 6. Step 2 — Canada localisation (proposal only, nothing changed)

Principle: **labels and seed data first; schema renames only with approval.**

Change type key:
- **L** — UI label/copy
- **S** — new seed/data migration
- **R** — schema rename (needs approval)
- **N** — no change

### 6.1 Legislation, regulators, terminology

| AU term | Where | Canadian equivalent | Change |
|---|---|---|---|
| WHS / WHS Act 2011 / WHS Regulation 2017 | Placeholders `audits/templates/new/AuditTemplateForm.tsx:84`, `compliance-calendar/new/ComplianceCalendarForm.tsx:108`; seed `20260610000007_training_course_seed.sql:67`; demo `scripts/seed-demo.mjs:245,251,269,541,542,623` | Provincial OHS legislation, Ontario first: *Occupational Health and Safety Act, R.S.O. 1990, c. O.1* and O. Reg. 851 (Industrial Establishments); BC *Workers Compensation Act* Part 2 + OHS Regulation; AB *OHS Act*; QC *Act respecting occupational health and safety* (LSST); federal *Canada Labour Code* Part II | L + S (new course seed rows, versioned) |
| Safe Work Australia, WorkSafe Victoria, SafeWork NSW (jurisdiction `AU`, `AU-VIC`, `AU-NSW`) | `20260606000016_module21_seed.sql:4,7,8`; placeholder `ComplianceCalendarForm.tsx:180` | Ontario MLITSD; WSIB (ON); WorkSafeBC; WCB Alberta + Alberta OHS; CNESST (QC); WCB per remaining province/territory; ESDC Labour Program (federal); CCOHS | S (new seed, jurisdiction codes `CA`, `CA-ON`, `CA-BC` …; deactivate the AU rows, don't delete them) |
| ISO / OSHA rows | same seed | Keep ISO 45001. Add CSA Z45001 / CSA Z1000. Keep OSHA as a reference only. | S |
| WorkCover / workers' comp | not found in the code | WSIB (ON), WorkSafeBC, WCB (AB, SK, MB, NS, NB, NL, PE, YT, NT/NU), CNESST (QC) | S (part of the regulator seed) |
| PCBU / duty of care | `seed-demo.mjs:542` | "Employer" / "constructor" (ON) duties | S (demo) |
| SWMS / Safe Work Method Statement | Doc type code `swms`: `20260605000040_module10_seed.sql:8`, `20260609000002_seed_document_types_statuses.sql:5`; demo `seed-demo.mjs:263` | "Safe Work Procedure (SWP)". Add a separate "Field Level Hazard Assessment (FLHA)" doc type. | L + S now (rename the display `name`). **R** for code `swms` → `swp` (needs approval; data migration, since `seed-demo.mjs` looks it up by code) |
| JSA | `jsas`, `jsa_*` tables, `/jsa` route, `generate_jsa_number` | JSA and JHA are both used in Canada. The UI already says "JSA / JHA". | N |
| HSE Officer | Role name `'HSE Officer'` (`20260604000004_module1_seed.sql:20`), `is_hse_officer()` (~330 RLS refs), `app/actions/permits.ts:155` | Display "Health & Safety Manager". Separately model **Health and Safety Representative** (ON: 6–19 workers) and **JHSC member / certified member** (ON: 20+ workers) as designations on `user_profiles` or `worker_competencies`, not as access roles. | L only. **Do not rename the role.** |
| Toolbox talk | `toolbox_talk_*` | Same term used in Canada (also "safety talk", "tailgate meeting") | N |
| EWP (elevating work platform) | `20260610000004_risk_template_seed.sql:10` | Aerial work platform (AWP) / elevating work platform (CSA B354) | S |
| TRIFR / LTIFR | KPI codes `20260605000060_module17_seed.sql:6-18`; formula keys `20260605000058_module17_triggers.sql:54,73` | TRIR / LTIR (or LTIF) on a 200,000-hour base | **Decision** (C10). Proposal: add new KPI rows `TRIR` / `LTIR` with the 200k base and keep the old codes inactive. |
| SDS | `chemical_sds` etc. | SDS is correct under WHMIS 2015 | N |
| Dangerous Goods | not found | TDG (Transportation of Dangerous Goods) if added later | N |

### 6.2 Business identifiers and addresses

| AU term | Where | Canadian equivalent | Change |
|---|---|---|---|
| ABN ("Australian Business Number (11 digits)") | Column `contractors.abn` (`20260608000004_module_contractors_schema.sql:5`); `app/actions/contractors.ts:27`; `contractors/page.tsx:18,25,38`; `contractors/new/ContractorForm.tsx:54-57`; `contractors/[id]/page.tsx:65,173` | CRA Business Number (9 digits, plus program account e.g. `123456789 RT0001`). Add WSIB/WCB account number and clearance-certificate expiry for contractors. | L now (label + helper + 9-digit validation). **R** `abn` → `business_number` (needs approval). Alternative: add `business_number`, backfill and leave `abn` deprecated. |
| ACN / "Pty Ltd" | Placeholder `app/(auth)/register/page.tsx:321`; demo org "EXXIO Demo Pty Ltd" | "Inc." / "Ltd." / "Corp." | L + demo |
| State / suburb / postcode | `sites.address` jsonb keys (comment `20260604000001_module1_schema.sql:38`); `app/actions/onboarding.ts:11,24-25`; `OnboardingWizard.tsx:120,217-218` (placeholder "NSW") | Province (2-letter code), city, postal code (`A1A 1A1`) | L + S (JSONB key backfill `state`→`province`, `postcode`→`postal_code`). Proposed: add a `sites.province` column (additive, not a rename), needed for site-level rules and holidays. |
| +61 phone placeholder | `workers/[id]/emergency-contacts/new/EmergencyContactForm.tsx:85,95` | `+1 (416) 555-0100` | L |
| `.com.au` | `wellbeing/new/WellbeingResourceForm.tsx:168` | `.ca` | L |
| Regulatory jurisdiction placeholder "Australia, NSW, National" | `regulatory/new/RegulatoryForm.tsx:117` | "Ontario", "Federal" — ideally a province picker | L |

### 6.3 Locale, currency, time

| AU item | Where | Canadian equivalent | Change |
|---|---|---|---|
| `en-AU` formatting (~102 calls in ~80 files; no central helper) | e.g. `components/table/DataTableClient.tsx:153,160,166`, `components/shell/AppShell.tsx:145`, most `app/(platform)/*/[id]/page.tsx` | `en-CA` (French `fr-CA` later for QC) | L: introduce `lib/format.ts` (`fmtDate`, `fmtDateTime`, `fmtCurrency`) and replace local helpers |
| AUD | `maintenance/[id]/page.tsx:29`, `assets/[id]/page.tsx:37`, `DataTableClient.tsx:166`, `assets/[id]/edit/EditForm.tsx:135` | CAD | L |
| AU timezones; default `Australia/Sydney` | `app/(auth)/register/page.tsx:36-41,143`; `settings/organisation/OrgForm.tsx:11-17` | America/St_Johns, Halifax, Toronto, Winnipeg, Regina, Edmonton, Vancouver, Whitehorse; default America/Toronto | L |
| `dd/mm/yyyy` placeholders + DD/MM parsers | `PpeForm.tsx`, `ChemicalForm.tsx`, `ActionForm.tsx`, `SpeakUpForm.tsx`, `ComplianceCalendarForm.tsx`, `IncidentForm.tsx`, `incidents/[id]/edit/EditForm.tsx`; parsers in `app/actions/chemicals.ts:58-63` and the form files | ISO `YYYY-MM-DD` (CSA / Government of Canada standard; avoids DD/MM vs MM/DD ambiguity) | L + parser change |
| "Organisation" spelling in visible UI (17 labels) | `app/admin/*`, `settings/organisation/*`, `register/page.tsx`, `AppShell.tsx:165,580`, etc. | "Organization" | L only; identifiers unchanged (C7) |
| Demo seed script | `scripts/seed-demo.mjs`: Sydney addresses, ABNs, 04xx phones, WHS Act, SafeWork NSW, PCBU, SWMS | Ontario demo org (e.g. Mississauga), BNs, 416/905 numbers, OHSA, MLITSD, WSIB | Script rewrite (not a migration) |

### 6.4 Already Canadian (no change)

- WHMIS course seed
- `organisations.province` and `organisations.country_code DEFAULT 'CA'`
- `applicable_provinces` columns
- `employment_jurisdiction_rules.province_code`, with ON/BC/AB/QC seeded and OHSA / WorkSafeBC orientation docs
- `en-CA` and CAD in hiring and BGC
- BGC `issuing_province`

---

## 7. Step 3 preview — training reconciliation (for agreement before planning)

| Incomplete Features / brief | Existing | Proposed |
|---|---|---|
| `training_courses` | Exists | Extend: `training_type` (course, induction, toolbox_talk, external_cert, refresher), versioning (`training_course_versions`, current version pointer, `requires_refresher_on_new_version`) |
| `training_records` | Exists | Extend: `course_version_id`, `assignment_id`, score/pass, `superseded_by`; derive `expiry_date` from the course validity; time-based status recompute |
| `training_requirements` / spec `cert_requirements` | `training_needs_matrix` (role only) | New data-driven `training_assignment_rules` (role, site, province, activity flags, due offset, recurrence, effective dating). Keep `training_needs_matrix` and migrate its rows into rules. |
| (missing) assignments | — | New `training_assignments` (worker, course version, due date in business days, status assigned/in_progress/completed/overdue/waived, source rule) |
| `training_schedules` | `toolbox_talk_schedules` only | New `training_sessions` + attendees for classroom delivery, or reuse the toolbox schedule pattern. Decide in the Step 3 plan. |
| `training_evidence` | `certificate_file_url` on records | New `training_evidence` (multiple files per record, storage path) |
| `competency_types` / `worker_competencies` / spec `external_certs` | `worker_licences` (BGC) | **Decision:** (a) new `competency_types` + `worker_competencies`, with `worker_licences` kept for BGC and a view unifying them; or (b) generalise `worker_licences` by adding `competency_type_id`. Recommend (a). |
| `toolbox_talks` / `toolbox_talk_attendees` | `toolbox_talk_deliveries` / `toolbox_talk_attendees` | Keep. Add `training_course_id` on templates. On attendee acknowledgment, create a `training_records` row. |
| Functions `generate_training_number`, `check_training_expiry`, `notify_training_due`, `mark_overdue_training` | `generate_training_number` (broken, D1), `check_expiring_training` | Fix D1 by routing through `next_reference_number`. Add the rest with de-duplication. |
| Trigger: sync `has_expired_competencies` on `user_profiles` | — | Add |
| RLS: own / team (supervisor) / site (HSE) | Org-only `FOR ALL` | Rewrite in the module-1 style |
| Notification templates, webhooks (`training.completed`, `training.expired`, `competency.expired`), KPI `TRAINING_COMPLIANCE` | Only `training.expiring_soon`, `training.overdue` | Add |
| Business-day deadlines with provincial holidays | None | New `statutory_holidays` data table + `add_business_days(date, int, province)` SQL function, shared by all modules |
| Seed: WHMIS, ON Worker/Supervisor Awareness, first aid, working at heights, forklift | WHMIS, WAH-101 exist | Add the rest, all flagged `is_sample_content = true` / "LEGAL REVIEW REQUIRED" |

---

## 8. Step 4 preview — rules engine

Spec 5.2 (rules, rule versions, obligations, compliance score) is **Missing** as a general capability. Existing building blocks are listed in §4. A design proposal will be produced after training and approved before any build. Inputs it must cover:

- Migrate `employment_jurisdiction_rules` + `runComplianceCheck`.
- Generalise `training_assignment_rules`.
- Give `compliance_obligations` a province and a source rule.
- Provide a compliance score that feeds the dashboard.

---

## 9. Open questions

1. **Spec.** Is there a fuller "Dev Build Spec v1" (with §4.2 roles, §5.2 rules engine, §6.9 training, Appendix B)? If so, this document should be re-run against it.
2. **Manager roles (C3).** Accept the 3-to-1 display mapping in §2.2, or collapse the roles?
3. **Defect fixes (§5).** Fix D1, D2, D4, D7, D8 and D12 in a fix set before Step 3 (recommended), or fold them into the training module?
4. **Competencies (C4).** New `worker_competencies` alongside `worker_licences` (recommended), or generalise `worker_licences`?
5. **Statutory holidays.** Store as dated rows per province per year (`statutory_holidays`, sample-flagged, Peninsula-editable — recommended), or as computed rules (e.g. "third Monday of February")? Rows are simpler to edit and audit.
6. **Test stack.** pgTAP via `supabase test db` for RLS, expiry and business-day tests, plus vitest for TS utilities (recommended)? This requires a working local `supabase db reset`, which D5 and D6 may currently break.
7. **TRIFR vs TRIR (C10).** Switch to the 200,000-hour base?
8. **`contractors.abn`.** Rename to `business_number`, or add a new column and deprecate the old one?
9. **`swms` doc type code.** Change the code, or display name only?
10. **E-signature provider (C6).** Is native signature acceptable for MVP?
11. **French / Quebec.** Is `fr-CA` in scope for MVP? It affects how content versioning tables store text.
