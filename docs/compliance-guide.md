# EXXIO / Peninsula — Compliance Guide for the Owner

**Prepared:** 2026-10-28 · **Covers:** the platform as it stands on branch `foundation/step-0-2` and the live Supabase project `oygrhongvmaxphzvmpcd`.
**Companion document:** [docs/gap-analysis.md](gap-analysis.md) (technical detail, defect numbers D1–D31).

> **This is not legal advice.** It is a working checklist to help you brief an employment lawyer, a privacy lawyer and an OHS consultant, and to run the business's compliance year. Every legal point below links to a source. Where the source was a secondary one or the point was not confirmed, it says **"confirm with counsel."** Laws and rates change; the sources were checked on 2026-10-28.

## How to read this

Each action has a **priority**:

| Priority | Meaning |
|---|---|
| **Now** | Before you sign or onboard the first paying customer, or right away because something is already wrong |
| **Before launch** | Before general availability or a public marketing push |
| **6 months** | Within six months of launch |
| **Ongoing** | Recurring; see the calendar in §10 |

And a **who**: *You* (owner), *Dev* (your engineering team), *EmpLaw* (employment lawyer), *PrivLaw* (privacy/technology lawyer), *OHS* (an OHS consultant or Peninsula's in-house health and safety advisers), *QC* (Quebec counsel/translator).

---

## 1. Do now — the short list

| # | Do this | Why (one line) | Who | Where in the platform |
|---|---|---|---|---|
| 1 | **Move the database to Canada.** The live Supabase database resolves to AWS **ap-southeast-1 (Singapore)**. Create a new project in Canada (Central) and migrate before any real customer data goes in. | Canadian employers, especially in Quebec, public sector and health care, will ask where data lives; Quebec requires a privacy impact assessment before personal information leaves the province ([Law 25 summary, CFIB](https://www.cfib-fcei.ca/en/site/qc-law-25)). Moving later is far harder. | You + Dev | Supabase project settings (region can't be changed in place — confirm with Supabase) |
| 2 | **Fix the stale minimum wages and termination-notice values** in the hiring rules (table below, §2.2). Ontario is $17.95 since 1 Oct 2026; the platform says $17.20. | The hiring compliance check will pass offers that are below the legal minimum. | EmpLaw reviews, Dev loads | `employment_jurisdiction_rules` |
| 3 | **Turn on the "sample content" flag everywhere** and show it in the UI: the older system courses (WHMIS-2015, HVP-101, EVAC-101, MMH-101, WAH-101), HR templates, consent template, risk templates. | Customers must not mistake unreviewed content for legal advice. Today only the newest courses carry the flag. | Dev | `training_courses`, `hr_document_templates`, `bgc_consent_templates`, `risks` (templates) |
| 4 | **Rename or deactivate `WAH-101 "Working at Heights Awareness"`** (12-month validity, not flagged). | Ontario construction workers need *CPO-approved* Working at Heights training valid 3 years ([ontario.ca](https://www.ontario.ca/page/training-working-heights)). An in-house "awareness" course can be mistaken for it. | OHS + Dev | `training_courses` |
| 5 | **Decide the background-check adverse-action process** (US FCRA pattern today) — see §5. Rewrite the consent template so it doesn't claim PIPEDA governs employee data. | The template is legally inaccurate for most Ontario employers and is unlocked (`is_locked = false`). | PrivLaw + EmpLaw | `bgc_consent_templates`, `lib/background-checks/` |
| 6 | **Get the core contracts drafted:** Terms of Service, Data Processing Agreement, Privacy Policy, subprocessor list, compliance disclaimer (§8). | You will be processing employees' health, injury and criminal-record data on customers' behalf. | PrivLaw | Website / order form |
| 7 | **Name your privacy officer** and publish their title and contact details. | Required for any business operating in Quebec (default is the CEO) ([Gowling WLG](https://gowlingwlg.com/en/insights-resources/articles/2022/bill-64-ceo-new-default-privacy-officer)); expected under PIPEDA accountability ([OPC](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/pipeda-compliance-help/pipeda-compliance-and-training-tools/gl_acc_201204/)). | You | Website, privacy policy |
| 8 | **Upgrade Supabase to Pro (or higher)** to get leaked-password protection and proper backups; add MFA for admins. | Security questionnaires ask for these; the app has no MFA today and leaked-password protection is Pro-only (gap analysis §5.4). | You (billing) + Dev | Supabase dashboard; app login |
| 9 | **Write a breach response plan** (one page: who decides, who calls the customer, regulator forms, 2-year breach log). | Mandatory breach reporting applies under PIPEDA, Alberta PIPA and Quebec Law 25 (§4.4). | You + PrivLaw | — |
| 10 | **Seed the statutory holidays for every province you sell into** (only federal + Ontario 2026–27 exist). | Business-day deadlines (dispute windows, due dates) are wrong for BC/AB/QC customers. | Dev, checked by EmpLaw | `statutory_holidays` |

---

## 2. Legal content the platform ships — review register

The platform ships "system" content that customers will rely on. Treat every row below as legal content: it needs a named reviewer, a review date, and a refresh schedule. A simple way to manage this: add `reviewed_by`, `reviewed_on` and `next_review_due` to each content table (or one `content_reviews` register), and only clear the "sample" flag once a reviewer has signed off.

### 2.1 Summary register

| Content | Where it lives | Why it matters | Reviewer | Refresh | Priority |
|---|---|---|---|---|---|
| Minimum wages, notice periods, probation, vacation-pay rules (ON, BC, AB, QC) | `employment_jurisdiction_rules` (seed: `supabase/migrations/20260608054815_hiring_jurisdiction_seed.sql`); checks hardcoded in `runComplianceCheck` (`app/actions/hiring.ts`) | Drives the "compliant / not compliant" verdict on every hire | EmpLaw | ON 1 Oct, BC 1 Jun, QC 1 May each year; AB when announced; other rules yearly | **Now** (values are stale) |
| Statutory holidays | `statutory_holidays` (`20261028124238_statutory_holidays_and_business_days.sql`) — federal `CA` and Ontario `CA-ON`, 2026–27 only | Business-day maths for deadlines and the BGC dispute window | Dev, spot-checked by EmpLaw | Every autumn, next year for every province | **Now** for provinces you sell into |
| Training courses (system) | `training_courses` where `organisation_id IS NULL`; seeds `20260606195222_…training_course_seed.sql`, `20261028132142_training_assignments.sql` | Customers will assign these to meet legal training duties | OHS | Yearly + on law change | **Now** (flagging), **Before launch** (review) |
| Competency types and validity periods | `competency_types` (8 rows, all 36 months except JHSC) | Expiry alerts and "is this worker qualified" | OHS | Yearly | Before launch |
| Training assignment rules | `training_assignment_rules` | Who must take which course by when | OHS | Yearly | Before launch |
| Regulators list | `regulatory_bodies` (`20261028131319_canada_reference_data.sql`) | Shown in compliance and incident screens | OHS | Yearly; add remaining provinces/territories | Before launch |
| PPE standards (CSA) | `ppe_types.standard_reference` (same migration) | Customers cite these in PPE programs | OHS | When CSA republishes (check yearly) | Before launch |
| Offer letter, employment contract, NDA, probation notice | `hr_document_templates` (`is_system_template`, v1.0, `applicable_provinces` empty) | Customers will send these to new hires | EmpLaw (+ QC for French) | Yearly + on law change | **Before launch** |
| BGC consent template | `bgc_consent_templates` "Standard Canadian Consent Form" v1, **unlocked** (seed `20260608062858_bgc_seed.sql`) | Consent must be valid for the check to be lawful | PrivLaw + EmpLaw | Yearly | **Now** |
| Adverse-action pre-notice / final notice emails | `lib/background-checks/email.ts`; logic `app/actions/background-checks.ts`, `lib/background-checks/adverse-action.ts` | Sent to rejected candidates | EmpLaw | Yearly | **Now** (process decision, §5) |
| Notification templates (64) | `notification_templates` | Wording of alerts about incidents, training, hires | You (tone), OHS for incident wording | Yearly | 6 months |
| Risk assessment templates (22: general 7, construction 5, food 5, retail 5) | `risks` where `is_template` (`20260606195117_…risk_template_seed.sql`) | Starting point for customers' hazard assessments | OHS | Yearly | Before launch |
| KPI formulas (TRIR/LTIR on 200,000 hours) | `kpi_definitions`, `compute_kpi_snapshot` (`20261028131246_kpi_trir_ltir_and_holiday_fallback.sql`) | Reported to boards, insurers and clients | OHS | On change | 6 months |
| In-code hiring guidance (wizard text) | `components/hiring/HiringWizard.tsx` | Step-by-step legal guidance not stored as data | EmpLaw | Yearly | Before launch |

### 2.2 Hiring rules — what's wrong today (live values, checked 2026-10-28)

| Province | Platform value | Current law | Source | Action |
|---|---|---|---|---|
| ON general minimum wage | $17.20 (eff. 2024-10-01) | **$17.95 from 2026-10-01** | [Hicks Morley](https://hicksmorley.com/2026/04/01/ontario-minimum-wage-to-increase-october-1-2026/), [U Waterloo](https://uwaterloo.ca/human-resources/news/minimum-wage-changes-effective-october-1-2026) — confirm on ontario.ca | Add new effective-dated row |
| ON student minimum wage | $16.20 | **$16.90 from 2026-10-01** | [Landscape Ontario](https://landscapeontario.com/?p=170740) — confirm on ontario.ca | Add row |
| BC general minimum wage | $17.40 (eff. 2024-06-01) | **$18.25 from 2026-06-01** | [BC Gov News](https://news.gov.bc.ca/releases/2026lbr0021-000581) | Add row |
| QC general minimum wage | $15.75 (eff. 2024-05-01) | **$16.60 from 2026-05-01** | [Québec.ca](https://www.quebec.ca/nouvelles/actualites/details/le-taux-general-du-salaire-minimum-passera-a-1660-lheure-le-1er-mai-2026-68123) | Add row |
| QC tipped minimum wage | $12.60 | **$13.30 from 2026-05-01** | same | Add row |
| AB general minimum wage | $15.00 | $15.00 (unchanged since 2018) | [Peninsula Canada guide](https://www.peninsulacanada.ca/resource-hub/minimum-wage/alberta-minimum-wage-guidelines/) — confirm on alberta.ca | None; add student rate ($13) if used |
| BC notice, under 1 year | 0 days | **1 week after 3 consecutive months** (2 weeks after 12 months) | [gov.bc.ca, ESA s.63](https://www2.gov.bc.ca/gov/content/employment-business/employment-standards-advice/employment-standards/forms-resources/igm/esa-part-8-section-63) | Fix |
| ON "probation_max 90" | 90 days | The ESA has no "probation" concept; it exempts employees employed **less than 3 months** from termination notice. Contract probation clauses are a common-law question. | [ontario.ca ESA guide](https://www.ontario.ca/document/your-guide-employment-standards-act-0) — confirm with counsel | Relabel the rule; have EmpLaw write the check |
| All provinces `stat_holiday_pay_pct = 4` | Mislabelled — it's **vacation pay**, and it ignores the step-up (e.g. 6% after 5 years in ON/BC/AB; after 3 years in QC) | Confirm per province with EmpLaw | Rename key; add tenure tiers |

Also note: Ontario's **new job-posting rules** (in force 1 Jan 2026, employers with 25+ employees) require a pay range no wider than $50,000, disclosure of AI use in screening, a statement on whether the vacancy exists, no "Canadian experience" requirement, and follow-up with interviewed applicants ([ontario.ca](https://www.ontario.ca/document/your-guide-employment-standards-act-0/requirements-related-publicly-advertised-job)). The platform has no job-posting feature today; if you add one, build these in. **6 months.**

### 2.3 Training content — review notes

| Course / competency | Status | Issue to review |
|---|---|---|
| ON-WHSA / ON-SHSA (Worker / Supervisor Health and Safety Awareness) | Sample, no expiry | Correct that there's no expiry. Supervisors must complete within **one week** of supervising; employers must give proof on request and the Ministry suggests keeping records 6 months after the worker leaves ([ontario.ca guide](https://www.ontario.ca/document/guide-occupational-health-and-safety-act-requirements-basic-awareness-training)). Check the assignment rule uses 7 days for supervisors. |
| ON-WAH (CPO-approved), 36 months | Sample | Correct validity ([ontario.ca](https://www.ontario.ca/page/training-working-heights)). The platform can only *record* this training — it must be delivered by a CPO-approved provider. Say so in the course description. |
| WAH-101 Working at Heights Awareness, 12 months | **Not flagged** | Confusable with ON-WAH (§1 item 4). |
| WHMIS-2015, 12 months | **Not flagged** | Most jurisdictions require WHMIS worker education to be **reviewed at least annually** rather than "expiring"; confirm wording with OHS ([CCOHS WHMIS](https://www.ccohs.ca/oshanswers/chemicals/whmis_ghs/general.html)). |
| HVP-101 Harassment & Violence Prevention, 24 months | **Not flagged** | Ontario requires the *policies* to be reviewed yearly and workers to be informed of the program; check that 24 months is defensible ([ontario.ca Part III.0.1](https://www.ontario.ca/document/guide-occupational-health-and-safety-act/part-iii0i-workplace-violence-and-workplace-harassment)). |
| SFA-CPR-C, 36 months | Sample | Ontario first-aid requirements come from **Regulation 1101 under the WSIA** (WSIB-approved providers) ([WSIB](https://www.wsib.ca/sites/default/files/2026-08/0455a_firstaidreqs_eng_web_202607.pdf)). Confirm validity per provider. |
| JHSC-1 (Part One) | Sample | Part Two and refreshers are missing; certification rules — confirm with OHS. |
| LIFT-TRUCK, 36 months | Sample | Ontario has no fixed statutory retraining interval in the regulation; 3 years is a common industry practice (CSA B335). Confirm with OHS. |
| Competencies (aerial work platform, confined space, fall protection, traffic control, etc.), all 36 months | Sample | Validity varies by province and standard. Review each. |
| Province coverage | ON-centric | BC (e.g. WorkSafeBC young/new worker orientation), AB and QC equivalents are not seeded yet. |

---

## 3. OHS obligations the platform helps with — and where it falls short

**Key:** ✅ = EXXIO supports it today · 🟡 = partial · ❌ = not supported. "Customer duty" means the employer remains legally responsible; the platform only helps them do and prove it.

### 3.1 Incident reporting deadlines

| Jurisdiction | What must be reported, by when | Source | EXXIO today |
|---|---|---|---|
| **Ontario – MLITSD** | Death or **critical injury**: notify an inspector **immediately** (phone), written report to the Director **within 48 hours**; don't disturb the scene. Other incidents (e.g. disabling injuries, fires, explosions, workplace violence without critical injury) — written notice **within 4 days**. Content of report: O. Reg. 420/21. | [ontario.ca reporting](https://www.ontario.ca/page/reporting-workplace-incidents-and-illnesses); [CCOHS](https://www.ccohs.ca/oshanswers/legisl/legislation/injury_reporting.html) | 🟡 Incidents, alerts and a `regulatory_submissions` table exist, but `regulatory_due_date` is a plain date: no auto-calculated 48-hour / 4-day deadline, no "critical injury" classification, no O. Reg. 420/21 field set. |
| **Ontario – WSIB (Form 7)** | When a worker needs health care beyond first aid, loses time or wages, or needs modified work for more than 7 days: WSIB must **receive** Form 7 **within 3 business days** of the employer learning of it; give the worker a copy. | [WSIB Form 7 guide](https://wsib.ca/en/employers-report-injury-disease-form-7-reference-guide-businesses) | ❌ No Form 7 mapping or deadline. Business-day function exists (`add_business_days`). |
| **BC – WorkSafeBC** | Serious injury, death, major structural failure or major hazardous release: notify **immediately** (WCA s.68). Employer's report of injury (Form 7) **within 3 days**. | [CCOHS](https://www.ccohs.ca/oshanswers/legisl/legislation/injury_reporting.html); [WorkSafeBC Form 7](https://media.sd64.bc.ca/media/Default/medialib/form-7-wsbc.c306856899.pdf) | ❌ |
| **Alberta – OHS and WCB** | Death, likely hospital admission, uncontrolled explosion/fire/flood: report to a Director **as soon as possible** (OHS Act s.33). WCB employer report **within 72 hours**. | [CCOHS](https://www.ccohs.ca/oshanswers/legisl/legislation/injury_reporting.html) | ❌ |
| **Quebec – CNESST** | Death, loss of a limb, significant physical trauma, injuries to several workers, or major property damage (indexed threshold): notify **within 24 hours** (LSST s.62); inform the H&S committee and representative. Keep a register of accidents. | [CCOHS](https://www.ccohs.ca/oshanswers/legisl/legislation/injury_reporting.html); [ACQ form](https://www.acq.org/wp-content/uploads/2023/08/sst-documents-f5-enquete-et-analyse-d-accident-chantier.pdf) — confirm current threshold with CNESST | ❌ |
| **Federal (Canada Labour Code Part II)** | Death, disabling injury to 2+ employees, permanent impairment, explosion: **within 24 hours** (COHSR s.15.5); written report follows — confirm timing. | [CCOHS](https://www.ccohs.ca/oshanswers/legisl/legislation/injury_reporting.html) | ❌ |

**Product gap to close (6 months, Dev + OHS):** a per-province "reportable incident" rule set that classifies the incident, calculates each deadline in hours or business days using the customer's province, and produces a pre-filled report/checklist. This is a strong selling point and a liability risk if a deadline is shown wrongly — have OHS sign off on each rule.

### 3.2 Other Ontario OHS duties

| Duty | Rule | Source | EXXIO today |
|---|---|---|---|
| Health & safety representative / JHSC | 6–19 workers: one worker-selected H&S representative. 20+: JHSC (2+ members under 50 workers, 4+ at 50+), half non-management, at least two certified members. | [ontario.ca guide](https://www.ontario.ca/page/guide-health-and-safety-committees-and-representatives) | 🟡 `jhsc_certified` competency and JHSC-1 course exist. No designation of reps/members, no meeting minutes, no monthly inspection link, no headcount-based prompt. |
| Mandatory awareness training (O. Reg. 297/13) | All workers and supervisors; supervisors within one week; records and proof on request. | [ontario.ca](https://www.ontario.ca/document/guide-occupational-health-and-safety-act-requirements-basic-awareness-training) | ✅ Courses, assignment rules, records, certificates (sample content). |
| Working at Heights (construction) | CPO-approved program; valid 3 years; refresher = practical module. | [ontario.ca](https://www.ontario.ca/page/training-working-heights) | 🟡 Recorded as a competency; no check that the provider was CPO-approved on the training date. |
| WHMIS 2015 | Worker education, labels, SDSs. | [CCOHS](https://www.ccohs.ca/oshanswers/chemicals/whmis_ghs/general.html) | 🟡 Chemical register and SDS are GHS-based; no workplace-label tracking, no SDS currency check, no annual education review prompt (gap analysis §1.1). |
| Workplace violence and harassment (Part III.0.1) | Written policies, reviewed **at least yearly**; posted if 6+ workers; written harassment program developed with JHSC/rep; violence risk assessment; investigations. | [ontario.ca Part III.0.1](https://www.ontario.ca/document/guide-occupational-health-and-safety-act/part-iii0i-workplace-violence-and-workplace-harassment); [Code of practice](https://www.ontario.ca/page/code-practice-address-workplace-harassment) | 🟡 Documents with review workflows, speak-up reports, HVP course. No policy-annual-review template, no harassment-investigation workflow with the confidentiality the code of practice expects. |
| First aid (Reg. 1101 under WSIA) | First aid station, kit contents by headcount, trained first aider, posted WSIB "In Case of Injury" poster (Form 82). | [WSIB](https://www.wsib.ca/sites/default/files/2026-08/0455a_firstaidreqs_eng_web_202607.pdf) | 🟡 First-aid competency; no kit inspection checklist seeded. |
| Electronic monitoring and disconnecting-from-work policies (ESA, 25+ employees) | Written policies in place by 1 March each year | [ontario.ca](https://www.ontario.ca/document/your-guide-employment-standards-act-0/written-policy-electronic-monitoring-employees) | ❌ Could be offered as templates. **Also applies to your own company** once you have 25+ employees. |

### 3.3 Other provinces — what to scope before selling there

| Province | Main differences to plan for | Before selling there |
|---|---|---|
| **BC** | Workers Compensation Act Part 2 + OHS Regulation; joint committees at 20+ workers; WorkSafeBC is both regulator and insurer; young/new worker orientation; BC Human Rights Code s.13 on convictions (§5). | Seed BC holidays, courses, reporting rules; fix notice rule. |
| **Alberta** | OHS Act and Code; committees/representatives by headcount; separate OHS (regulator) and WCB (insurer). | Same. |
| **Quebec** | LSST as modernised by the 2021 reform (prevention programs/action plans, committees and representatives — confirm current phase-in with QC counsel); CNESST; **French language** (§6); Law 25 privacy (§4). | French UI and documents; QC counsel review. Treat as its own launch. |
| **Federal** | Canada Labour Code Part II for banks, telecom, interprovincial transport, etc.; PIPEDA applies to employee data. | Decide whether you sell to federal employers at all. |

### 3.4 Record retention the platform should support

| Record | Minimum period | Source |
|---|---|---|
| Ontario ESA employment records (name/address/start date, hours, wages, leave) | 3 years (vacation records 5 years) | [ontario.ca](https://www.ontario.ca/document/your-guide-employment-standards-act-0/record-keeping) |
| O. Reg. 297/13 awareness training proof | No set period; Ministry suggests at least 6 months after the worker leaves | [ontario.ca](https://www.ontario.ca/document/guide-occupational-health-and-safety-act-requirements-basic-awareness-training/records) |
| Privacy breach records (PIPEDA) | 2 years | [OPC](https://www.priv.gc.ca/en/privacy-topics/privacy-for-businesses/privacy-breaches-at-your-business/gd_pb_201810/) |
| Incident, exposure, JHSC, designated-substance records | Varies — some exposure records run for decades | Confirm with OHS per regulation |

**EXXIO today:** only `documents` has a `retention_policy` field; nothing deletes or archives automatically, and there is no legal-hold flag. **Gap (6 months):** a per-record-type retention schedule (customer-configurable, with legal minimums as floors), legal hold, and end-of-contract export and deletion.

---

## 4. Privacy and data

### 4.1 Which law applies (this surprises people)

| Situation | Law | Source |
|---|---|---|
| **Your company's** handling of customer contacts, website visitors, billing (commercial activity) | PIPEDA (or AB/BC PIPA, Quebec private-sector act where applicable) | [OPC](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/r_o_p/02_05_d_26/) |
| **Employee** data of an Ontario (provincially regulated) employer | **PIPEDA does not apply**; there is no general private-sector employee privacy statute in Ontario. Still: contract, common-law privacy torts, human-rights and OHS confidentiality rules. | [OPC](https://www.priv.gc.ca/en/privacy-topics/employers-and-employees/02_05_d_18/), [FPT resolution](https://www.priv.gc.ca/en/about-the-opc/what-we-do/provincial-and-territorial-collaboration/joint-resolutions-with-provinces-and-territories/res_231005_02/) |
| Employee data of BC or Alberta employers | BC PIPA / Alberta PIPA | same |
| Employee data of Quebec employers | Quebec private-sector act as amended by **Law 25** | [CFIB](https://www.cfib-fcei.ca/en/site/qc-law-25) |
| Federally regulated employers, and anything in the territories | PIPEDA | [OPC](https://www.priv.gc.ca/en/privacy-topics/employers-and-employees/02_05_d_18/) |

In practice your customers are the **controllers** of their employees' data; you are their **service provider/processor**. Your DPA (§8) must say so and commit you to the strictest standard you'll meet (in practice Quebec's). Customers in Ontario will still expect PIPEDA-grade protection by contract.

**Consequence for the platform:** the BGC consent template says it "is governed by PIPEDA" — wrong for most Ontario hires and for QC/AB/BC. **Now:** have PrivLaw rewrite it with a jurisdiction-neutral statement or province variants.

### 4.2 Actions

| # | Action | Why | Who | Priority |
|---|---|---|---|---|
| P1 | Appoint and publish a privacy officer (§1) | Law 25; PIPEDA accountability | You | **Now** |
| P2 | **Data residency:** move the database from Singapore to Canada; check where Vercel functions, storage and Resend email process data; document it | Customer expectation; Quebec cross-border PIA (s.17) ([McCarthy Tétrault on the CAI PIA guide](https://www.mccarthy.ca/en/insights/blogs/techlex/quebec-privacy-regulators-guide-law-25-compliant-privacy-impact-assessments)); OPC cross-border guidance requires transparency ([OPC](https://www.priv.gc.ca/en/privacy-topics/airports-and-borders/gl_dab_090127/)) | You + Dev | **Now** |
| P3 | Do a privacy impact assessment of the platform (one for the product, reused for customers' own PIAs) | Law 25 requires PIAs for new systems handling personal info and before transfers outside Quebec; customers will ask for it | PrivLaw | Before launch |
| P4 | Subprocessor list (below), published, with change-notice process | DPAs require it | PrivLaw + You | Before launch |
| P5 | Retention and deletion: per-record-type schedules, end-of-contract export and deletion, backup expiry | Law 25 and PIPA require destruction when purpose ends; customers' DPAs will require it | Dev | 6 months |
| P6 | Data subject requests: a way for a customer admin to export/correct/delete one person's data | Access and correction rights in all regimes | Dev | 6 months |
| P7 | Health, medical, speak-up and BGC data: keep them restricted (already excluded from audit logs, see §7), add field-level access review and minimisation | These are "sensitive" in every regime ([OPC sensitive info](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/pipeda-compliance-help/pipeda-interpretation-bulletins/interpretations_10_sensible/)) | Dev + PrivLaw | Before launch |
| P8 | Embedded YouTube/Vimeo in training: consider privacy-enhanced embeds or self-hosting | Viewing data goes to Google/Vimeo | Dev | 6 months |
| P9 | Remove the email fallback `noreply@exxio.ai` sender before launch if branding is Peninsula; set SPF/DKIM/DMARC | Deliverability and phishing risk on consent emails | Dev | Before launch |

### 4.3 Subprocessors found in the code (confirm and complete)

| Provider | What it does | Data | Location |
|---|---|---|---|
| Supabase (on AWS) | Database, authentication, file storage, scheduled jobs | Everything | **AWS ap-southeast-1, Singapore** (resolved from the database host on 2026-10-28) — move |
| Vercel (assumed from the stack; confirm) | Web hosting, server functions | Everything in transit | Confirm function region (default is US) |
| Resend | Email (BGC consent, reference requests, adverse-action notices) | Candidate names, emails, roles | US — confirm |
| Certn (adapter written, **not live**) | Background checks | Candidate identity, DOB, results | Canadian provider — confirm data location in contract |
| YouTube / Vimeo | Embedded training video | Viewer IP/cookies | US |
| GitHub, your own laptops | Source code (no customer data should be there) | — | — |

### 4.4 Breach response — what the law asks

| Regime | Trigger | Who to tell | Source |
|---|---|---|---|
| PIPEDA | "Real risk of significant harm" | OPC and affected individuals, as soon as feasible; keep a record of **every** breach for 2 years | [OPC](https://www.priv.gc.ca/en/privacy-topics/privacy-for-businesses/privacy-breaches-at-your-business/gd_pb_201810/) |
| Alberta PIPA | Real risk of significant harm | Alberta Information and Privacy Commissioner, without unreasonable delay | [OIPC AB decisions](https://oipc.ab.ca/wp-content/uploads/2022/05/P2022-ND-021.pdf) |
| BC PIPA | Historically no mandatory reporting for private sector — **confirm with counsel** (reform has been discussed) | — | — |
| Quebec Law 25 | Confidentiality incident with a "risk of serious injury" | CAI and affected persons promptly; keep an **incident register** | [Gazette officielle](https://www.publicationsduquebec.gouv.qc.ca/fileadmin/gazette/pdf_encrypte/lois_reglements/2022F/78638.pdf) |
| Your contracts | Usually "notify the customer without undue delay / within X hours" | Each affected customer | Your DPA |

As a processor, your first call is usually to the **customer**; they decide on regulator notice for their employees. Your own business data (customer contacts) is your call. Put both paths in the one-page plan.

---

## 5. Background checks in Canada

### 5.1 What Canadian law expects

| Topic | Rule | Source |
|---|---|---|
| Consent | Needed for the specific check; for Ontario police checks, the Police Record Checks Reform Act requires prior written consent to the *type* of check, and the individual sees the results before they go to the employer (further consent). | [Police Record Checks Reform Act, 2015](https://www.ontario.ca/laws/statute/15p30/v2); [Torkin Manes summary](https://www.torkin.com/insights/publication/new-system-of-police-record-checks-in-ontario) |
| Three Ontario check types | Criminal record check; criminal record and judicial matters check; vulnerable sector check (only for roles working with vulnerable people). Non-conviction information is generally not disclosed. | same |
| Human rights — Ontario | "Record of offences" (pardoned/record-suspended convictions, and provincial offences) is a protected ground. Otherwise a conviction may be considered only where it's genuinely linked to the job. | [Oakville procedure citing the Code](https://www.oakville.ca/town-hall/policies-procedures/recruitment-policy/police-record-check-procedure); [OHRC](https://www.ohrc.on.ca/en/news-center/letter-chief-paul-cook-ontario-association-chiefs-police-oacp-president) — confirm with counsel |
| Human rights — BC | Can't refuse to employ because of a criminal or summary conviction **unrelated** to the job (Human Rights Code s.13). | [LawNow](https://www.lawnow.org/?p=11504) — confirm on BC Laws |
| Human rights — Quebec | Charter s.18.2: can't refuse to hire over a conviction with no connection to the job, or if pardoned; courts have extended it to charges. | [LegisQuébec C-12](https://www.legisquebec.gouv.qc.ca/en/document/cs/C-12); [Blakes](https://www.blakes.com/insights/hires-dismissals-and-criminal-records-what-quebec-employers-need-to-know/) |
| Timing | Widely advised: run criminal, credit and similar checks **after a conditional offer**, so the check can't screen people out on protected grounds early. | [HR Reporter](https://www.hrreporter.com/chrr-plus/employment-law/can-employers-conduct-credit-checks-on-job-applicants/317164) — confirm with counsel |
| Credit checks (Ontario) | Consumer Reporting Act: the candidate must be told of the inquiry; if a decision relies on the report, the person must be told and given the agency's name. Credit checks need a clear job-related reason. | [Consumer Reporting Act](https://www.ontario.ca/laws/statute/90c33/v5); [HR Reporter](https://www.hrreporter.com/chrr-plus/employment-law/can-employers-conduct-credit-checks-on-job-applicants/317164) — confirm s.10 wording |
| Privacy | Collect only what the role needs; keep results restricted; destroy when no longer needed. | §4 |

### 5.2 The adverse-action pattern in the platform

The platform sends an **adverse-action pre-notice**, holds a **5-business-day dispute window**, then a **final notice** (`app/actions/background-checks.ts`, `lib/background-checks/adverse-action.ts`). That is the US Fair Credit Reporting Act pattern. Canada has **no** equivalent statutory "pre-adverse action" procedure or fixed dispute window (the Ontario Consumer Reporting Act disclosure duty above is the closest).

That doesn't make the feature wrong — giving a candidate a chance to explain or correct a record is good practice and helps employers defend human-rights complaints. But:

| Decision | Recommendation (confirm with EmpLaw) | Priority |
|---|---|---|
| Keep the pre-notice step? | Keep it, but call it a "**opportunity to respond**", not "adverse action", and make the window length **configurable per customer** (default 5 business days). | **Now** |
| Wording of notices | Remove US terminology; add the human-rights test (is the record related to the job?), and for credit reports name the agency. | **Now** |
| Province of the candidate | Store it on the BGC package so the business-day calculation uses the right holidays (the code already calls `add_business_days`, but only ON and federal holidays exist). | Now |
| Consent template | Lock a reviewed version per province; record which version each candidate signed (the tables already support this). | **Now** |
| Check types offered | `credit_check` and `criminal_vulnerable_sector` should require the customer to state a job-related reason before ordering. | Before launch |
| Provider | No live Canadian provider yet (Certn adapter is untested). You'll need a provider contract with its own DPA. | Before launch |

---

## 6. Language and accessibility

### 6.1 Quebec — French

| Requirement | What it means for you | Source | Priority |
|---|---|---|---|
| Work tools and software must be available in French where a French version exists; employees can ask for French work documents | A Quebec employer that buys EXXIO is expected to give staff a French version. If there's no French UI, you are competing against tools that have one. | [Éducaloi](https://www.educaloi.qc.ca/en/capsules/language-workplace-quebec); [Montréal International](https://www.montrealinternational.com/en/?p=40110) — confirm with QC counsel | Before selling in QC |
| Written employment contracts must be in French first (Bill 96); a contract of adhesion can be bound in another language only after the employee has seen the French version and expressly chooses otherwise | Offer letter and contract templates need **French versions** for QC hires | [Langlois](https://langlois.ca/en/?p=10416); [Miller Thomson](https://www.millerthomson.com/en/insights/publications/bill-96-quebec-french-language-law-overhaul/) | Before selling in QC |
| Your own contracts of adhesion (ToS) with Quebec customers | Must be offered in French first (confirm with QC counsel) | same | Before selling in QC |
| Francization (businesses with 25+ employees in Quebec register with OQLF) | Affects *you* only if you have 25+ employees in Quebec | same | Ongoing |

**Open decision (gap analysis §9 Q11):** is `fr-CA` in MVP? Decide now, because translated content (courses, templates, notifications) needs language columns or per-language versions in the content tables. Recommendation: build the data model for two languages now, ship Quebec later.

### 6.2 Accessibility — AODA and beyond

| Requirement | What it means | Source | Priority |
|---|---|---|---|
| Ontario businesses with 50+ employees must make **public** websites meet **WCAG 2.0 Level AA** | Applies to your marketing site once you reach 50 employees; customers will also ask in procurement whether the app meets WCAG 2.0/2.1 AA, because they must accommodate employees with disabilities | [ontario.ca](https://www.ontario.ca/page/how-make-websites-accessible) | Before launch (marketing site), 6 months (app audit) |
| Candidate-facing pages (BGC consent, reference forms) | Public-facing — treat as WCAG AA | same | Before launch |
| Accessible formats on request (AODA employment standard) | Certificates, policies, training material in accessible formats | Confirm with counsel | 6 months |

Action: run an automated and manual WCAG 2.1 AA audit (Carbon, the UI library you use, is built for accessibility, which helps) and publish an accessibility statement. Who: Dev, or an accessibility auditor.

---

## 7. Security assurance customers will ask for

Expect a security questionnaire from every mid-sized customer. Current answers:

| Question | Today | What to do | Priority |
|---|---|---|---|
| Where is data hosted? | Singapore (AWS ap-southeast-1) | Move to Canada (§1) | **Now** |
| Tenant isolation | ✅ Row-level security on every table, tested per role per table (`pnpm test:integration`, 46/46 passing); the critical exposures D18/D19/D30 were fixed on 2026-10-23 | Keep tests in CI; mention in answers | Ongoing |
| Encryption | Supabase encrypts in transit (TLS) and at rest (AWS) — confirm wording with Supabase docs | Cite in answers | Now |
| MFA | ❌ No MFA in the app | Enable Supabase Auth MFA (TOTP) at least for admins and HSE/BGC roles; offer SSO for larger customers | Before launch |
| Password protection | Leaked-password check needs Supabase **Pro** — currently Free | Upgrade | **Now** |
| Backups / disaster recovery | Free plan — confirm what's included; Pro adds daily backups, point-in-time recovery is an add-on | Upgrade; write an RPO/RTO statement and test a restore | Now / Before launch |
| Audit logs | ✅ `audit_logs` + `row_versions` on core, training, hiring, BGC, compliance, contractor tables. **Deliberately excluded:** speak-up reports, BGC results/adjudications/disputes/adverse-action notices, health and medical tables (so the log doesn't widen access). | Explain the exclusions; add a separate restricted access log for those tables | 6 months |
| Penetration test | None | Third-party pen test before launch, then yearly | Before launch |
| SOC 2 | None | SOC 2 Type I within ~6–12 months, Type II after; Supabase and Vercel have their own reports you can reference. Ask customers whether they need it before spending. | 6 months (decide) |
| Vulnerability management | Security advisors at 0 ERRORs | Schedule a monthly advisor review and dependency updates | Ongoing |
| Employee access to customer data | Platform super-admin console (`/admin`, service role) | Write an access policy; log super-admin actions; restrict to named staff | Before launch |
| Incident response | None written | §4.4 plan | **Now** |

---

## 8. Contracts and policies you need

| Document | Must cover | Who | Priority |
|---|---|---|---|
| **Terms of Service / Master Subscription Agreement** | Service description; **compliance disclaimer** (below); limitation of liability; customer responsibilities (they remain the employer, they verify content, they file reports); acceptable use; termination and data return | PrivLaw / commercial lawyer | **Now** |
| **Data Processing Agreement** | You act only on instructions; confidentiality; security measures; subprocessors and change notice; breach notice to customer (e.g. within 48–72 hours); assistance with access requests and PIAs; data location; deletion/return at end; audit rights | PrivLaw | **Now** |
| **Privacy Policy** (your own) | What you collect about customers/users; privacy officer contact; cross-border transfers | PrivLaw | **Now** |
| **Subprocessor list** | §4.3, kept current | You | Before launch |
| **Security overview / trust page** | Answers to §7 | You + Dev | Before launch |
| **SLA** | Uptime target, support hours, maintenance windows, credits | You | Before launch |
| **Candidate-facing notices** | BGC consent, reference request, response-opportunity notices — in the *customer's* name | EmpLaw | **Now** |
| **French versions** | ToS, DPA, templates for Quebec | QC | Before selling in QC |
| **Internal policies** (for your own company) | Information security, access control, acceptable use, incident response, data retention; and once you have 25+ Ontario employees, electronic monitoring and disconnecting-from-work policies | You | 6 months |

**Suggested disclaimer wording to give your lawyer:** "EXXIO provides tools and sample content to help employers manage health, safety and HR obligations. Sample content is provided for convenience, may not reflect the law in every jurisdiction or the latest changes, and is not legal advice. The customer remains responsible for its legal obligations, including reviewing content, meeting reporting deadlines and making employment decisions."

**Data ownership:** the contract should say the customer owns its data (including its employees' personal information); you get a limited licence to process it to provide the service, plus de-identified usage statistics if you want them (say so explicitly). You own the platform and your system content.

---

## 9. Open decisions with legal or compliance weight

| # | Decision | Options | Recommendation | Who decides |
|---|---|---|---|---|
| D-1 | Database region | Stay in Singapore / move to Canada (Central) | Move now, before customer data | You |
| D-2 | E-signature (gap analysis C6) | Native drawn/typed signature (today) / DocuSign-style provider | Native is generally allowed: Ontario's Electronic Commerce Act permits electronic signatures for most documents ([ontario.ca](https://www.ontario.ca/laws/statute/00e17)), and BC, AB and QC have similar laws. Strengthen the audit trail (timestamp, IP, document hash, signer identity check) — currently missing. Ask EmpLaw to confirm no excluded documents in your flows. | You + EmpLaw |
| D-3 | French (`fr-CA`) in MVP | Yes / later | Build bilingual-ready data model now; ship QC later | You |
| D-4 | Adverse-action / dispute window | Keep US model / Canadian "opportunity to respond" | §5.2 | You + EmpLaw |
| D-5 | Who maintains legal content | Peninsula's advisers / outside counsel / customers | Peninsula advisers own it with outside counsel sign-off; put names in the review register | You |
| D-6 | Liability for wrong legal content | Disclaim / warrant with cap | Disclaim + "sample" flag + review register; check your professional liability (E&O) and cyber insurance cover SaaS | You + broker |
| D-7 | Federal employers in scope? | Yes / no | Not for MVP; it adds PIPEDA employee rules and Canada Labour Code reporting | You |
| D-8 | TRIR/LTIR (C10) | Already added on 200,000-hour base | Keep TRIFR/LTIFR inactive; label clearly | Done — OHS to confirm |
| D-9 | Job-posting feature | Build / don't | If built, must meet Ontario 2026 posting rules (§2.2) | You |
| D-10 | Competencies vs BGC licences (C4) | Two tables / merge | Product decision; make sure one source drives expiry alerts so customers don't get conflicting answers | You |

---

## 10. Recurring compliance calendar

| When | Task | Who |
|---|---|---|
| **January** | Load next year's statutory holidays for every province you sell in (do it in **November** to be safe); check Ontario employer counts for your own electronic-monitoring/disconnecting policies (due 1 March) | Dev / You |
| **Q1** | Annual review of all system content (register in §2.1); update review dates | OHS, EmpLaw |
| **1 April** | Federal minimum wage changes (if you serve federal employers) | Dev |
| **By 1 May** | Quebec minimum wage (announced around January) | Dev, EmpLaw |
| **By 1 June** | BC minimum wage (announced around February–April) | Dev |
| **Mid-year** | Privacy review: subprocessor list, retention runs, access review of super-admin and BGC roles, breach log review | Privacy officer |
| **By 1 October** | Ontario minimum wage (announced by 1 April) | Dev |
| **Yearly** | Penetration test; restore-from-backup test; DPA/ToS refresh; insurance renewal | You, Dev |
| **Yearly** | Supabase/Vercel/Resend security report and terms review | You |
| **Monthly** | Supabase security advisors; dependency updates | Dev |
| **Continuous** | Legislation watch: subscribe to ontario.ca news, WSIB, WorkSafeBC, CNESST, OPC/CAI, and a law-firm employment bulletin (e.g. Hicks Morley, Fasken); log each change and the content it affects | You / OHS |

Tip: put these dates into the platform's own **compliance calendar** (`compliance_obligations`) under your own organisation — it's a good demo and it means you use what you sell.

---

## Facts not verified for this guide

- Ontario 2026 student wage and $17.95 rate came from secondary sources (law firm, university, trade body); confirm on ontario.ca.
- Alberta $15.00 and student rate: secondary sources; confirm on alberta.ca.
- Quebec CNESST property-damage reporting threshold for 2026 (indexed yearly).
- BC PIPA breach-notification status and any 2025–26 reform.
- Exact wording of Ontario Consumer Reporting Act s.10 and the Electronic Commerce Act exclusions.
- Quebec software-in-French rules (section numbers and enforcement) — secondary sources only.
- Vacation-pay tenure tiers by province (stated from general knowledge).
- Supabase backup inclusions on the Free plan; whether region change requires a new project; Vercel function region; Resend data location.
- The database region was inferred from the database host's IP address (AWS ap-southeast-1); confirm in the Supabase dashboard.
