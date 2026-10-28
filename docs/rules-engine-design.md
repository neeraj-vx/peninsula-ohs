# Rules Engine — Design Proposal (Step 4)

**Status:** Proposal for approval. Nothing in this document is built yet.
**Date:** 2026-10-28
**Inputs:** gap analysis §4 (existing rules), §8 (Step 4 preview), §9 (open questions); Step 3 training assignments (built 2026-10-28).

---

## 1. Problem

Compliance logic lives in four unrelated places today, each with its own shape:

| Where | What it does | Limits |
|---|---|---|
| `employment_jurisdiction_rules` + `runComplianceCheck()` (`app/actions/hiring.ts`) | Minimum wage, probation length, notice periods, required hire documents per province (31 rows: ON 9, QC 8, BC 7, AB 7) | Checks are hard-coded in TypeScript, one `if` per rule type. They only run during hiring. Until today they also ignored `effective_date` (D32, fixed in code). |
| `training_assignment_rules` (Step 3) | Which roles must complete which courses | Only covers training |
| `compliance_obligations` / `compliance_tasks` | Recurring obligations entered by hand (3 rows live) | Has no province, no source rule, and no link to what triggered it |
| `statutory_holidays` + `add_business_days()` | Deadline arithmetic | Federal + Ontario only, 2026–27 |

As a result, a customer can't answer "am I compliant in Ontario?" in one place, and Peninsula can't ship a legal change (a new minimum wage, a new mandatory course) as data. Each change is a code change.

## 2. Goals and non-goals

**Goals**
1. One model for "the law (or the customer's policy) says X must be true / done by Y".
2. Rules are **data**: versioned, effective-dated, jurisdiction-scoped, and reviewed before they are published. Legal changes ship without a deploy.
3. Each rule produces **obligations** for an organisation, site, worker or record. Each obligation has a due date in business days, an owner and evidence.
4. A **compliance score** per organisation, site and category feeds the dashboard and KPIs.
5. Existing modules keep working. Hiring checks and training assignments become rule types rather than separate systems.

**Non-goals**
- A general-purpose expression language or user-written code. Rule *types* are a fixed catalogue implemented in SQL. Rules only supply parameters.
- Legal advice. Every system rule carries a source citation and a review status, and the UI says so.

## 3. Concepts

| Concept | Meaning | Example |
|---|---|---|
| **Rule** | A stable identity for a requirement | "Ontario minimum wage (general)" |
| **Rule version** | The parameters in force for a date range, with source and review state | $17.60/h from 2025-10-01; $X from 2026-10-01 |
| **Applicability** | Who it applies to: jurisdiction, industry, headcount band, site type, role | ON, any industry, 20+ workers → JHSC |
| **Rule type** | Built-in evaluator (SQL function) that turns a version + subject into obligations or findings | `threshold`, `max_duration`, `required_training`, … |
| **Obligation** | A concrete thing an organisation must have or do, with status and due date | "Hold JHSC meeting — due 2026-12-31" |
| **Finding** | A pass/fail result of checking a record against a rule | "Hire HIR-0012: probation 120 days exceeds ON maximum 90" |
| **Compliance score** | Weighted share of obligations met and findings passed | Ontario OHS 86% |

## 4. Rule type catalogue (v1)

| Type | Parameters | Produces | Replaces / covers |
|---|---|---|---|
| `threshold` | field, operator, value, unit | Findings on records | minimum wage, stat-holiday pay % |
| `max_duration` | field, max days | Findings | probation maximum, notice periods |
| `required_document` | document type, subject (hire/site/org) | Obligation per subject | hire required docs; workplace violence & harassment policy |
| `required_training` | course, role/site filter, due-within business days | Training assignments (Step 3) | `training_assignment_rules` becomes this type's storage |
| `headcount_trigger` | min/max workers, then requirement | Obligation when the org crosses a band | ON H&S representative (6–19), JHSC (20+) |
| `periodic_obligation` | frequency, lead time | Recurring obligations | JHSC meetings, annual policy review, inspections |
| `event_deadline` | triggering event, deadline (business days), recipient | Obligation when the event occurs | WSIB Form 7 within 3 business days; critical injury notice "immediately" |
| `posting_requirement` | document/poster, location | Obligation per site | OHSA poster, ESA poster |

New types are added by migration (new evaluator function + catalogue row). Rules are added by data.

## 5. Data model

```text
rule_types          (code PK, name, description, parameter_schema jsonb)
rules               (id, code UNIQUE, name, category, rule_type, organisation_id NULL=system, is_active)
rule_versions       (id, rule_id, version, parameters jsonb, effective_from, effective_to,
                     source_citation, source_url, review_status draft|in_review|published|retired,
                     reviewed_by, reviewed_at, change_note)
rule_applicability  (id, rule_version_id, jurisdiction 'CA'|'CA-ON'|…, industry NULL,
                     min_headcount, max_headcount, site_type NULL, role_id NULL)
obligations         (= compliance_obligations, extended: source_rule_version_id, jurisdiction,
                     subject_type, subject_id, due_date, status, owner_id, evidence links)
rule_findings       (id, organisation_id, rule_version_id, subject_type, subject_id, passed,
                     severity, message, evaluated_at)
compliance_scores   (organisation_id, site_id NULL, category, period, score, numerator, denominator)
```

Key properties:
- **Exactly one published version in force per rule and date**, enforced with an exclusion constraint on `(rule_id, daterange(effective_from, effective_to))`. This is the general fix for D32.
- Organisations can add their **own** rules (`organisation_id` set). They can't edit system rules, but they can set an org-level override version where the type allows it (e.g. a stricter probation maximum).
- RLS follows the existing pattern: system rules are readable by every authenticated user, org rules use org scope, and writes are limited to safety managers. Only Peninsula (service role / super admin) can publish system rule versions.
- Audit triggers on all tables (D15 pattern). Rule versions are never updated after publishing; a change is a new version.

## 6. Evaluation

- `evaluate_rules(p_organisation_id, p_subject_type, p_subject_id)` dispatches each applicable published version to its type's evaluator: `eval_threshold(...)`, `eval_required_training(...)`, and so on.
- **When it runs:**
  - On change: triggers on hires, user_roles, sites, headcount changes and incidents, the same approach Step 3 uses for training.
  - Nightly: cron sweep for periodic and expiring obligations, reusing the de-duplication approach from D9.
  - On demand: the "Check compliance" button in hiring calls the evaluator instead of `runComplianceCheck`'s TypeScript.
- **Deadlines** always use `add_business_days(date, n, jurisdiction)`. Unseeded provinces fall back to federal holidays and are flagged in the UI.
- **Idempotent:** obligations are upserted on `(rule_version_id, subject_type, subject_id, period)`. Findings are replaced per evaluation.

## 7. Compliance score

`score = Σ weight × met / Σ weight` over obligations due to date plus active findings, grouped by category (OHS, Employment standards, Training, Privacy). Weights come from severity: critical = 3, standard = 1. It is exposed through the `compute_kpi_value_extra` hook added in Step 3 (`compliance_score`), so it appears in KPIs and on the home page with no further changes to `compute_kpi_snapshot`.

## 8. Migration of what exists

| Existing | Becomes | Notes |
|---|---|---|
| `employment_jurisdiction_rules` (31 rows) | `rules` + `rule_versions` (`threshold`, `max_duration`, `required_document`) | One-off data migration; table kept read-only as a view for one release |
| `runComplianceCheck()` checks 1–N | `evaluate_rules('hire', id)` | Same messages and severities; output format unchanged so the hiring UI doesn't change |
| `training_assignment_rules` | Storage for `required_training` | No data change; the rule row references it |
| `compliance_obligations` | `obligations` (add columns) | Existing rows become manual obligations (no source rule) |
| `statutory_holidays` | Unchanged | Seeding per province and year becomes part of rule content ops |

## 9. Content operations (Peninsula side)

1. A legal / OHS reviewer drafts a version with a source citation (`review_status = draft`).
2. A second reviewer approves it (`in_review` → `published`). The UI shows "Reviewed by Peninsula on <date>".
3. The annual calendar (e.g. Ontario minimum wage every 1 October, holidays every December) is tracked as Peninsula's own `periodic_obligation` rules in an internal organisation.
4. Sample or unreviewed content is flagged in the UI everywhere it is used. This continues the `is_sample_content` convention from Step 3.

## 10. Delivery plan

| Increment | Scope | Tests |
|---|---|---|
| R1 | Tables, RLS, audit, exclusion constraint, rule type catalogue; migrate `employment_jurisdiction_rules`; `threshold` + `max_duration` + `required_document` evaluators; hiring uses the evaluator | Parity test: old vs new hiring results on fixtures; effective-dating test (future version not applied early) |
| R2 | `required_training` wraps Step 3; `headcount_trigger` (H&S rep / JHSC); `periodic_obligation`; obligations UI in Compliance calendar | Headcount crossing creates/retires obligations; periodic generation idempotent |
| R3 | `event_deadline` for incident reporting (WSIB Form 7, critical injury) with business-day deadlines; notifications | Incident on Friday before a holiday → correct due date per province |
| R4 | Compliance score KPI + home page card; Peninsula review workflow screens; seed BC / AB / QC holidays and rules | Score maths; review state transitions; RLS for system vs org rules |

Each increment ships with integration tests in the existing Vitest suite, against throwaway `zz-test-*` organisations.

## 11. Decisions (settled 2026-10-28)

1. **Reviewer:** Peninsula publishes system rules; publishing requires a second person (enforced by `guard_rule_version`).
2. **Provinces:** Ontario first; other provinces' rule content later. Holiday calendars already cover every province and territory.
3. **Customer overrides:** customers may mark a rule "not applicable" with a reason (`rule_org_settings`); they cannot switch rules off. Stricter customer rules are deferred to R2.
4. **French:** not needed at launch; labels and messages stay single-language.

**R1 status: built** (`20261028151146_rules_engine_r1.sql`, `evaluate_hire_rules`, 9 integration tests). Next: R2 (`required_training`, `headcount_trigger`, `periodic_obligation`).

### Original questions

1. **Who reviews system rule content** (in-house OHS lead, external counsel, or both), and is two-person approval required?
2. **Launch provinces for rules content:** Ontario only for R1–R3, then BC / AB / QC in R4 (recommended)?
3. **Customer overrides:** may customers make a system rule *stricter* (allowed) or switch it off (recommended: no; they may mark it "not applicable" with a reason)?
4. **French (fr-CA)** for rule names and messages: needed for Quebec at launch? This affects whether `rule_versions` stores per-locale text.

## 12. Risks

| Risk | Mitigation |
|---|---|
| Wrong legal content shown as authoritative | Review workflow, citations, "Reviewed on" stamp, sample flags, guide in `docs/compliance-guide.md` |
| Evaluator performance on large orgs | Set-based SQL per type; nightly sweep batched per organisation |
| Parity regressions in hiring | R1 parity tests before switching the hiring UI over |
| Holiday calendars missing for a province | Federal fallback + UI warning; seeding is a tracked recurring obligation |
