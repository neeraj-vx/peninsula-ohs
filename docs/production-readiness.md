# EXXIO: Road to Production and Pitch

**Prepared:** 2026-11-03 · **Updated:** 2026-11-03 (legal pages built; items deferred by owner; new findings I15–I16)
**Branch:** `foundation/step-0-2` (not merged to `main` yet)
**Live project:** Supabase `oygrhongvmaxphzvmpcd`

**Sources.** This was checked against:
- the live project: 210 applied migrations, 270 tables, and today's security advisors
- the repo and its test suite (74 tests)
- [gap-analysis.md](gap-analysis.md), [rules-engine-design.md](rules-engine-design.md) and [compliance-guide.md](compliance-guide.md)

Use this as the single checklist. Each item has a **priority**, an **owner** and an **effort** estimate.

**Priority:**
- **P0:** must be done before any real customer data.
- **P1:** before paid launch.
- **P2:** within 6 months.
- **Pitch:** needed for demos and sales.

**Owners:**
- **Dev:** engineering.
- **You:** owner / business.
- **Law:** an employment, privacy or commercial lawyer.
- **OHS:** a health and safety consultant, or Peninsula's in-house advisers.

---

## 0. Where we are (one paragraph for the pitch deck)

The platform is functionally broad:
- **OHS:** about 30 modules, including incidents, risks, inspections, audits, permits, chemicals and SDS, PPE, JSA, LOTO, emergency, contractors, environment, health and fatigue.
- **HR:** training and LMS with auto-assignment rules, competencies and certificates; guided hiring with province rules; onboarding; background checks with a Certn adapter.
- **Platform:** rules engine (R1), statutory holidays for all 13 provinces and territories (2026–2030), business-day deadlines, MFA, audit trails, an AI assistant, and marketing pages with a full set of draft legal pages.

Security has been reworked:
- Row-level security is on for every table.
- Tenant isolation is tested for every role on every table.
- The advisors report 0 ERRORs.

**What stands between this and production:**
1. **Infrastructure.** The data sits in Singapore, the Supabase plan is Free, five file-storage buckets are publicly readable (I15), and there is no CI or monitoring.
2. **Legal review.** Terms, Privacy Policy, DPA and the other website policies are drafted and live in the code (§3.1), but no lawyer has reviewed them, and none of the shipped compliance content has been signed off.
3. **A few product gaps** that customers will expect: rules engine R2–R4, compliance score, French, billing, and real email and e-signature trails.

---

## 1. Infrastructure and DevOps

| # | Item | Status today | Action | Pri | Owner | Effort |
|---|---|---|---|---|---|---|
| I1 | **Database region** | The live project is in AWS **ap-southeast-1 (Singapore)** | Create a new Supabase project in **ca-central-1** and replay `supabase/migrations/`. Verifying the replay also closes D20. Move storage objects across and repoint Vercel env vars. | **P0** | Dev + You | 2–3 days |
| I2 | Supabase plan | Free (no leaked-password protection, limited backups) | Upgrade to **Pro**, turn on leaked-password protection, and add point-in-time recovery | **P0** | You | 1 hour + cost |
| I3 | Separate environments | One project serves as dev, demo and prod | Prod (Canada), staging (Supabase branch or second project) and a demo org. Never run integration tests against prod. | **P0** | Dev | 1 day |
| I4 | Unmerged work | All the foundation, training, rules and MFA work sits on `foundation/step-0-2` | Review, then merge to `main`. Vercel deploys from `main`. | **P0** | Dev | ½ day |
| I5 | CI | No `.github/workflows` | GitHub Actions running `pnpm lint`, `tsc`, `pnpm test` on every PR, and `test:integration` against staging | P1 | Dev | 1 day |
| I6 | Error monitoring and logs | None (no Sentry or similar) | Add Sentry (or Vercel Observability) for frontend and server actions, and alert on Supabase log errors | P1 | Dev | ½ day |
| I7 | Uptime and status | None | Uptime monitor and a public status page (needed for the SLA) | P1 | Dev | 2 hours |
| I8 | Backups and restore test | Not tested | Write down RPO/RTO and do one real restore drill | P1 | Dev | ½ day |
| I9 | Transactional email | Resend is used for BGC and contact emails; delivery of platform notifications through `notification_deliveries` hasn't been verified end to end | Verified sending domain (SPF/DKIM/DMARC), check every notification channel end to end, and handle bounces | P1 | Dev | 1–2 days |
| I10 | Custom domain and subdomains | `exxio.ai` rebrand done; per-org subdomains exist | Decide on the production domain (Peninsula brand?), TLS for the wildcard, and a cookie domain check | P1 | You + Dev | ½ day |
| I11 | SECURITY DEFINER exposure | The advisor lists **98 WARN** functions executable by `authenticated` (most are trigger functions or are org-guarded after D31) | Revoke EXECUTE on trigger-only functions and keep the RPCs that are meant to be called. Aim for 0 WARN. | P1 | Dev | 1 day |
| I12 | RLS with no policies (INFO) | `bgc_consent_tokens`, `marketing_leads`, `reference_counters` and the `super_admin_*` tables are service-role only, which is intended | Add a comment or an explicit deny note so security reviews don't flag them | P2 | Dev | 1 hour |
| I13 | Performance | Not load-tested | Run the advisor's performance pass (indexes on FKs and RLS helper calls) and a load test with a 500-employee org | P2 | Dev | 2 days |
| I14 | Mobile | A PWA shell exists | An offline write queue for incidents, toolbox talks and inspections, then a field test on phones | P2 | Dev | 1 week |
| I15 | **Public file storage** *(new, found 2026-11-03)* | Buckets `documents`, `certificates`, `sds-documents`, `hazard-evidence` and `signatures` are `public = true`. Anyone with a link can read a file, and policies `anon_insert_*` let **anyone, without signing in, upload** to them (`20261103170000_storage_buckets.sql`). Signatures, hazard photos and certificates can contain personal information. | Make the buckets private. Store paths instead of public URLs, serve files through signed URLs after an org/role check, and drop the anon insert policies. The Privacy Policy and DPA describe access-controlled records, so fix this before customer data goes in. | **P0** | Dev | 1–2 days |
| I16 | **AI file reader uses the service role** *(new, found 2026-11-03)* | `lib/ai/files.ts` checks that the user can see the record (RLS), but then downloads the file path stored on that record with `supabaseAdmin`. File URL columns are user-editable, so a user could point one of their records at another organization's storage path and have the assistant read that file. `lib/ai/tools.ts` also writes AI-drafted PDFs to the public `documents` bucket. | Download with the user's own client, or check that the path starts with the caller's `organisation_id/`. Save drafts to the private bucket. Folds into A14. | **P0** | Dev | ½ day |

---

## 2. In-app product: what's left to build

### 2.1 Must-have before paid launch (P1)

| # | Item | Status | What's needed | Effort |
|---|---|---|---|---|
| A1 | **Rules engine R2**: `required_training`, `headcount_trigger` (Ontario H&S rep at 6–19 workers, JHSC at 20+), `periodic_obligation` | Designed (rules-engine-design §10) | Build it and add obligations to the compliance calendar | 1 week |
| A2 | **Rules engine R3**: incident reporting deadlines (WSIB Form 7, critical injury notice to MLITSD) in business days | Designed | Build it, with notifications | 1 week |
| A3 | **Rules engine R4: compliance health score** on the home page and dashboard | Designed | This is the headline pitch feature (Overview §5), along with the Peninsula review and publish screens | 1 week |
| A4 | **Billing and subscriptions** | Missing; pricing shows "Contact us" | Stripe (CAD, per-employee or tiered), trial, seat limits, invoices, dunning. Super-admin can see plan status. | 1–2 weeks |
| A5 | **"Sample content" flag visible everywhere** | **Deferred by owner (2026-11-03).** Only the newest courses carry it | Flag older courses, HR templates, the BGC consent template and risk templates, and add a UI badge with a "reviewed on" date (compliance-guide §1 #3). The new Compliance Content Disclaimer page partly covers the gap, but in-app badges are still needed before launch. | 1–2 days |
| A6 | **E-signature audit trail** | Native drawn or typed signature only | Add timestamp, IP, user agent, document SHA-256 hash and signer identity to every signature, plus a signed PDF certificate (compliance-guide D-2) | 3 days |
| A7 | **Canadian adverse-action flow for BGC** | Uses the US FCRA pattern | Replace it with a Canadian "opportunity to respond" flow once Law confirms the approach (compliance-guide §5) | 2–3 days |
| A8 | **Certn live integration** | The adapter exists; only the stub has been tested | Sandbox account, end-to-end test, webhook signature check, error states | 3–5 days |
| A9 | **Data retention and deletion** | None. **The Terms and DPA now promise** a 30-day export window after cancellation, deletion within a further 30 days, and written confirmation of deletion. The Privacy Policy promises that enquiries are kept for at most 2 years. | Retention settings per record type (compliance-guide §3.4), whole-org export, org deletion with a certificate, and a scheduled purge of `marketing_leads` older than 2 years | 3–4 days |
| A10 | **Super-admin access controls** | **Deferred by owner (2026-11-03).** `/admin` uses the service role; impersonation is already logged (`logSuperAdminAction`) | Named staff only, MFA, and customer-visible access logs | 2 days |
| A11 | **Restricted access log** for speak-up, BGC results and health records | **Deferred by owner (2026-11-03).** Deliberately left out of the audit triggers | A separate read-access log for these sensitive tables | 2 days |
| A12 | **Onboarding polish** | Wizard and starter pack exist | First-run path: org → sites (with province) → invite users → pick industry pack → first training rule. Measure time to first value. | 2–3 days |
| A13 | **Role UX** | 6 roles in the database; sidebar filtered by role | Confirm the Manager mapping (gap-analysis §2.2) and hide write buttons the user's RLS will reject | 2 days |
| A14 | **AI assistant guardrails** | Chat with data tools and approvals. Database reads use the user's own client (RLS), but file reads and draft uploads use the service role (I16). Vercel AI Gateway and Anthropic are now listed on the Subprocessors page. | Fix I16, add an in-chat "not legal advice" note, rate limits, and a retention period for saved chats (`ai_chat_sessions`) | 2–3 days |
| A15 | **Record Terms acceptance** *(new)* | Sign-up now shows "By creating an account, you agree to the Terms…" with links, but nothing is stored | Store the accepted Terms version, a timestamp and the user on the organization at sign-up, and ask admins to re-accept after a material change (Terms §17 promises 30 days' notice) | ½ day |

### 2.2 Should-have (P2, within 6 months)

| # | Item | Notes |
|---|---|---|
| B1 | **French (fr-CA)** UI and content | Needed to sell in Quebec (Bill 96 / Law 25). Data model should be bilingual-ready (compliance-guide D-3). |
| B2 | Province rule content beyond Ontario (BC, AB, QC) | Rules engine content plus Law review. Holiday calendars are already done. |
| B3 | SSO (SAML/OIDC) for larger customers | `sso_providers` table exists; no UI or flow yet |
| B4 | HRIS integrations (BambooHR, etc.) | `integration_types` seeded; no connectors |
| B5 | Advanced analytics and report builder polish | KPIs are fixed and TRIR/LTIR added; scheduled report emails need verifying |
| B6 | WHMIS specifics | Supplier and workplace labels, 3-year SDS currency check, link to WHMIS training |
| B7 | Accessibility (AODA / WCAG 2.1 AA) | Audit and fixes (compliance-guide §6.2) |
| B8 | Native mobile app | Only if PWA feedback demands it |
| B9 | Job postings | Must meet Ontario 2026 posting rules if built (compliance-guide D-9) |
| B10 | PPE low-stock and inspection-due alerts; fatigue rule evaluator | Tables exist; logic is missing |

### 2.3 Engineering hygiene

**Deferred by owner (2026-11-03).** Kept here so it isn't lost:

- Get the 98 WARN advisors to 0 (I11). Re-run the advisors after every migration.
- Integration tests in CI against staging, not prod (I3, I5).
- Regenerate `lib/database.types.ts` from the live schema, and remove `any` casts around Supabase queries.
- Update `INCOMPLETE_FEATURES.md`; it is stale. The gap analysis is now the source of truth.
- Remove or replace the old `scripts/seed-demo.mjs`, which is Australian. The new `scripts/demo/*.sql` is Canadian.
- Every new feature ships with demo seed data (per house rule).
- ESLint isn't configured: there is no `eslint.config.*`, so `pnpm lint` can't run. Add a flat config before CI (I5).

---

## 3. Compliance, legal and content (outside the app)

The full detail is in [compliance-guide.md](compliance-guide.md). The short list is below.

### 3.1 Website legal pages: built 2026-11-03

All pages are under `/legal`, are public (allowed in `middleware.ts`), and are linked from a new "Legal" column in the marketing footer. Sign-up links to the Terms and Privacy Policy, and the contact form links to the Privacy Policy. Company details live in one config: `LEGAL` in `components/marketing/legal.tsx`.

| Page | Route | File |
|---|---|---|
| Legal index | `/legal` | `app/(marketing)/legal/page.tsx` |
| Terms of Service | `/legal/terms` | `app/(marketing)/legal/terms/page.tsx` |
| Privacy Policy | `/legal/privacy` | `app/(marketing)/legal/privacy/page.tsx` |
| Data Processing Addendum | `/legal/data-processing` | `app/(marketing)/legal/data-processing/page.tsx` |
| Subprocessors | `/legal/subprocessors` | `app/(marketing)/legal/subprocessors/page.tsx` |
| Acceptable Use Policy | `/legal/acceptable-use` | `app/(marketing)/legal/acceptable-use/page.tsx` |
| Cookie Notice | `/legal/cookies` | `app/(marketing)/legal/cookies/page.tsx` |
| Compliance Content Disclaimer | `/legal/disclaimer` | `app/(marketing)/legal/disclaimer/page.tsx` |
| Accessibility Statement | `/legal/accessibility` | `app/(marketing)/legal/accessibility/page.tsx` |

**Written from how the platform actually works.** I left out claims that aren't true yet: staff training, regular advisory reviews, a documented incident process, per-person data export, and an accessibility audit. The Privacy Policy states that data is currently stored in Singapore, because Canadian privacy law expects cross-border storage to be disclosed.

**Before these pages are relied on:**

| # | Action | Owner |
|---|---|---|
| W1 | **Lawyer review of every page.** They are drafts, not reviewed legal text. Pay most attention to limitation of liability, indemnities, the Quebec language clause (Bill 96 rules for contracts of adhesion) and the breach-notice timing. | Law |
| W2 | Fill in the `TODO` fields in `LEGAL`: the registered **legal entity name** (currently just "EXXIO"), **business address**, and **privacy officer's name** | You |
| W3 | Create and monitor the mailboxes the pages publish: `legal@`, `privacy@`, `security@` and `support@exxio.ai` | You |
| W4 | When the database moves to Canada (I1), set `LEGAL.dataRegion` and `dataInCanada: true`. Then update the Supabase row on the Subprocessors page and give customers 30 days' notice of any subprocessor change (DPA §6). | Dev |
| W5 | Confirm subprocessor locations: Vercel function region, Resend, Anthropic via AI Gateway, and Certn's data location in its contract. Add Stripe and Sentry when they are introduced (A4, I6). | You + Dev |
| W6 | Change `lastUpdated` in `LEGAL` whenever any page changes, and keep old versions (git history works) | Dev |

**Commitments these pages make, which the product and the business must honour:**

| Commitment | Where | Backed by |
|---|---|---|
| 30-day export window after cancellation, deletion within a further 30 days, written confirmation | Terms §10, DPA §10 | A9 (not built; manual deletion until then) |
| Trial data deleted 30 days after the trial ends | Terms §9 | A9 |
| Enquiries kept for at most 2 years | Privacy §8 | A9 purge job |
| Customer notified of a security incident within 72 hours of confirming it | DPA §8 | L4 breach plan |
| 30 days' notice before a subprocessor changes, with a right to object | DPA §6 | W4 / process |
| Reply to privacy requests within 30 days | Privacy §9 | W3 mailbox + process |
| 30 days' notice of material Terms changes | Terms §17 | A15 |
| 60 days' notice of fee changes at renewal; 10 days' notice before suspending for late payment | Terms §8 | A4 billing |
| No Customer Data used to train AI models, and no sale of data | Terms §5, DPA §3 | Confirm the AI Gateway and Anthropic terms (W5) |
| Staff access to customer data is logged | Privacy §7, DPA §4 | `logSuperAdminAction` (exists) |
| Reply to accessibility requests within 5 business days | Accessibility §4 | W3 mailbox |
| French Terms provided on request to Quebec organizations | Terms §18 | L16 |

### 3.2 Everything else

| # | Item | Pri | Owner |
|---|---|---|---|
| L1 | **Terms of Service / MSA** with a compliance disclaimer. **Drafted** (§3.1); needs lawyer review (W1), plus an order-form template for sales-led deals | **P0** | Law |
| L2 | **Data Processing Agreement.** **Drafted** as a web addendum (§3.1). Larger customers will want a signable version. | **P0** | Law |
| L3 | **Privacy Policy** (**drafted**, §3.1) and a **named Privacy Officer** (still to appoint; W2) | **P0** | You + Law |
| L4 | **Breach response plan** (one page) plus a 2-year breach log (PIPEDA, Alberta PIPA, Quebec Law 25) | **P0** | You + Law |
| L5 | **Legal review of all shipped content**: hiring rules (minimum wages, notice), training courses (WHMIS, Ontario Worker / Supervisor Awareness, first aid, working at heights), HR templates, BGC consent template, risk templates, holiday calendars marked `needs_review`. Record each sign-off in the review register (compliance-guide §2.1). | **P0** | Law + OHS |
| L6 | **Fix stale legal values** (for example Ontario minimum wage, $17.95 since 1 Oct 2026). Check live values against compliance-guide §2.2. | **P0** | Law → Dev |
| L7 | **Rename or deactivate `WAH-101`.** It could be mistaken for CPO-approved Ontario Working at Heights training. | **P0** | OHS + Dev |
| L8 | **Who owns legal content going forward**: Peninsula advisers with outside counsel sign-off. Two-person publish is already enforced in the rules engine. | P1 | You |
| L9 | **Subprocessor list.** **Published** at `/legal/subprocessors` (Supabase, Vercel incl. AI Gateway, Anthropic, Resend; optional Certn and YouTube/Vimeo). Locations still to confirm (W5). | P1 | You |
| L10 | **Insurance**: E&O / professional liability and cyber, covering wrong legal content and breaches | P1 | You + broker |
| L11 | **Privacy Impact Assessment** (needed for Quebec customers; good practice anyway) | P1 | Law |
| L12 | **Candidate-facing notices** (BGC consent, reference requests) issued in the customer's name | P1 | Law |
| L13 | **Security assurance**: third-party penetration test before launch, a security overview or trust page, and a SOC 2 Type I decision within 6–12 months | P1 / P2 | You + Dev |
| L14 | **SLA**: uptime target, support hours, credits | P1 | You |
| L15 | **Internal policies** for your own company: infosec, access control, acceptable use, retention. The customer-facing Acceptable Use Policy is published; these are separate internal policies. | P2 | You |
| L16 | **French versions** of ToS, DPA and templates before selling in Quebec | P2 | Law (QC) |
| L17 | **Recurring calendar** (compliance-guide §10): yearly holiday load in November, minimum wage changes, annual content review, yearly pen test and restore test | Ongoing | You / Dev |

---

## 4. Go-to-market and pitch readiness

| # | Item | Status | Action | Pri |
|---|---|---|---|---|
| G1 | **Brand decision** | **Decided 2026-11-03: EXXIO.** The code already uses it | Finish domain, logo and deck branding as EXXIO | **Pitch** |
| G2 | **Demo org** | **Demo script and module-coverage check deferred by owner (2026-11-03).** `scripts/demo/*.sql` seeds a Canadian demo across modules, with a login-page demo | Script a 15-minute demo path: incident → WSIB deadline → corrective action → training auto-assigned → hire with province check → BGC → compliance score. Make sure AI features appear in the demo org. | **Pitch** |
| G3 | **Compliance score on the home page** | Not built (A3) | It's the single most persuasive screen. Build it before the pitch if possible. | **Pitch** |
| G4 | **Pricing** | "Contact us" placeholder | Set per-employee CAD tiers, for example a 10–500 employee SMB band (Overview open question 7) | **Pitch** |
| G5 | **Pitch deck** | None | Problem → 3–4 tools today → all-in-one → differentiators (BGC, guided hiring, e-sign, province content, analytics) → demo → security and data residency → pricing → roadmap | **Pitch** |
| G6 | **Security one-pager** | **Deferred by owner (2026-11-03).** Material is in compliance-guide §7 | Canada hosting (after I1), RLS-tested tenant isolation, MFA, audit trails, backups. Fix I15 first so it can claim private file storage. | **Pitch** |
| G7 | **Competitor benchmark** | None | 1 page against existing OHS tools (Overview open question 8) | **Pitch** |
| G8 | **Marketing site** | Home, How it works, Pricing, Contact and **9 legal pages** (§3.1) are built; leads go to `marketing_leads` | Add a trust/security page and a case-study placeholder, route lead notifications to sales, and add `sitemap.ts` / `robots.ts` | P1 |
| G9 | **Pilot customers** | None | 2–3 Ontario SMBs on a free pilot with signed pilot terms, a feedback loop and success metrics | P1 |
| G10 | **Support** | None | Help-centre articles (the per-screen info popups are a start), a support inbox, onboarding call script | P1 |
| G11 | **Open business questions** (Overview §10) | Unanswered | Canada-only? Launch provinces (recommend Ontario first)? Human advisory vs AI? Preferred BGC provider? Payroll in scope? E-sign provider? | **Pitch** |

---

## 5. Suggested sequence

**Done 2026-11-03:** G1 brand (EXXIO); website legal pages (§3.1).
**Deferred by owner 2026-11-03:** A5, A10, A11, G2 demo script, G6 security one-pager, engineering hygiene (§2.3). Pick these up again before launch.

**Week 1: pitch-ready**
- G4 and G11 decisions.
- A3 compliance score (or a convincing version of it).
- G5 deck.
- **I15 + I16 storage and AI file fixes** (small, and they back the claims on the legal pages).
- Merge to `main` (I4).

**Weeks 2–3: production foundations (P0)**
- I1 move to Canada, I2 Pro, I3 environments.
- W1–W3 lawyer review of the legal pages, entity and privacy officer details, mailboxes.
- L4 breach plan.
- L5–L7 content review.

**Weeks 4–6: launch blockers (P1 engineering)**
- A1, A2 rules engine R2/R3.
- A4 billing.
- A6 e-sign trail, A7 adverse-action flow, A8 Certn live.
- A9 retention (needed for the promises in §3.1), A14 AI guardrails, A15 Terms acceptance record.
- I5–I10 CI, monitoring, email.

**Weeks 6–8: pilot**
- G9 pilots.
- L13 penetration test.
- G10 support.
- Fix whatever the pilots turn up.

**After launch (P2)**
- B1 French plus B2 other provinces, in that order if Quebec is a target.
- SSO and HRIS.
- SOC 2 decision.

---

## 6. Decisions needed from you now

1. ~~**Product name and brand** for the pitch~~ **Decided: EXXIO.** (G1)
2. **Approve the move to a Canadian Supabase project** and the Pro upgrade. (I1, I2)
3. **Pricing model and numbers.** (G4, A4)
4. **Which lawyers and OHS advisers** will review the drafted legal pages and the shipped content, and by when. (W1, L5–L8)
5. **The legal entity name, business address and privacy officer** to put on the legal pages. (W2)
6. **BGC provider**: Certn, or another? (A8)
7. **Quebec at launch, or later?** This drives French, including French versions of the legal pages. (B1, L16)
