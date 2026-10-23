INSERT INTO hr_document_templates
  (organisation_id, template_type, name, description, body_content, province_clauses, variable_definitions, is_active, is_system_template, version)
VALUES
(
  NULL, 'offer_letter', 'Letter of Offer',
  'Standard letter extending a job offer to a candidate. Covers role, start date, compensation, and reporting structure.',
  '{{employer_name}}

Date: {{document_date}}

Dear {{employee_full_name}},

We are pleased to offer you the position of {{position_title}} with {{employer_name}}, commencing on {{start_date}}.

POSITION DETAILS

Title: {{position_title}}
Employment Type: {{employment_type}}
Location: {{site_name}}
Reporting To: {{reports_to_name}}
Start Date: {{start_date}}

COMPENSATION

{{compensation_summary}}

This offer is contingent upon satisfactory completion of applicable pre-employment checks and your ability to legally work in Canada.

Please indicate your acceptance of this offer by signing and returning this letter by {{offer_expiry_date}}.

We look forward to welcoming you to our team.

Sincerely,

{{employer_signatory_name}}
{{employer_signatory_title}}
{{employer_name}}

ACCEPTANCE

I, {{employee_full_name}}, accept the offer of employment as described above.

Signature: _______________________________  Date: ___________',
  '{"ON":"This offer is governed by the Employment Standards Act, 2000 (Ontario). The probation period shall not exceed 3 months (90 days) from the start date.","BC":"This offer is governed by the Employment Standards Act (British Columbia). Any probationary period shall not exceed 3 months from the start date.","AB":"This offer is governed by the Employment Standards Code (Alberta). Any probationary period shall not exceed 3 months (90 days) from the start date.","QC":"Cette offre est regie par la Loi sur les normes du travail (Quebec). Toute periode de probation ne depassera pas 3 mois a compter de la date de debut."}'::jsonb,
  '[{"key":"employer_name","label":"Employer Name","required":true},{"key":"document_date","label":"Document Date","required":true},{"key":"employee_full_name","label":"Employee Full Name","required":true},{"key":"position_title","label":"Position Title","required":true},{"key":"start_date","label":"Start Date","required":true},{"key":"employment_type","label":"Employment Type","required":true},{"key":"site_name","label":"Work Location / Site","required":true},{"key":"reports_to_name","label":"Reporting Manager Name","required":false},{"key":"compensation_summary","label":"Compensation Summary","required":true},{"key":"offer_expiry_date","label":"Offer Expiry Date","required":false},{"key":"employer_signatory_name","label":"Signatory Name","required":true},{"key":"employer_signatory_title","label":"Signatory Title","required":true}]'::jsonb,
  true, true, '1.0'
),
(
  NULL, 'employment_contract', 'Employment Contract',
  'Comprehensive employment agreement covering all key terms and conditions of employment. Includes jurisdiction-specific clauses.',
  'EMPLOYMENT AGREEMENT

This Employment Agreement is entered into as of {{start_date}} between:

EMPLOYER: {{employer_name}}
EMPLOYEE: {{employee_full_name}}

1. POSITION AND DUTIES

The Employee is hired as {{position_title}}, reporting to {{reports_to_name}}. Primary place of work: {{site_name}}.

2. EMPLOYMENT TYPE

{{employment_type_clause}}

3. PROBATION PERIOD

The Employee will serve a probationary period of {{probation_period}} from the start date.

4. COMPENSATION

{{compensation_summary}}

5. VACATION AND STATUTORY HOLIDAYS

The Employee is entitled to vacation pay at a minimum of {{vacation_pay_pct}}% of gross earnings.

6. TERMINATION

Either party may terminate this Agreement with written notice as required by applicable employment standards legislation.

7. CONFIDENTIALITY

The Employee agrees to maintain the confidentiality of all proprietary information of the Employer during and after employment.

8. GOVERNING LAW

This Agreement is governed by the laws of {{governing_province}}, Canada.

SIGNATURES

Employee: _______________________________  Date: ___________
{{employee_full_name}}

Employer: _______________________________  Date: ___________
{{employer_signatory_name}}, {{employer_signatory_title}}',
  '{"ON":"ONTARIO EMPLOYMENT STANDARDS ACT NOTICE\n\nThis Agreement is subject to the Employment Standards Act, 2000 (Ontario). In the event of any conflict between this Agreement and the ESA, the ESA prevails. The Employee acknowledges receipt of the ESA poster.","BC":"BRITISH COLUMBIA EMPLOYMENT STANDARDS ACT NOTICE\n\nThis Agreement is subject to the Employment Standards Act (British Columbia). In the event of any conflict, the ESA prevails.","AB":"ALBERTA EMPLOYMENT STANDARDS CODE NOTICE\n\nThis Agreement is subject to the Employment Standards Code (Alberta). In the event of any conflict, the Code prevails.","QC":"LOI SUR LES NORMES DU TRAVAIL (QUEBEC)\n\nLa presente convention est soumise a la Loi sur les normes du travail (Quebec). En cas de conflit entre la presente convention et la Loi, la Loi prevaut."}'::jsonb,
  '[{"key":"employer_name","label":"Employer Name","required":true},{"key":"employee_full_name","label":"Employee Full Name","required":true},{"key":"start_date","label":"Start Date","required":true},{"key":"position_title","label":"Position Title","required":true},{"key":"reports_to_name","label":"Reporting Manager","required":false},{"key":"site_name","label":"Work Location","required":true},{"key":"employment_type_clause","label":"Employment Type Description","required":true},{"key":"probation_period","label":"Probation Period","required":true},{"key":"compensation_summary","label":"Compensation Summary","required":true},{"key":"vacation_pay_pct","label":"Vacation Pay Percentage","required":true},{"key":"governing_province","label":"Governing Province","required":true},{"key":"employer_signatory_name","label":"Signatory Name","required":true},{"key":"employer_signatory_title","label":"Signatory Title","required":true}]'::jsonb,
  true, true, '1.0'
),
(
  NULL, 'nda', 'Non-Disclosure Agreement (NDA)',
  'Confidentiality agreement protecting proprietary business information. Effective from start date.',
  'NON-DISCLOSURE AND CONFIDENTIALITY AGREEMENT

This Agreement is entered into as of {{start_date}} between {{employer_name}} and {{employee_full_name}}.

1. CONFIDENTIAL INFORMATION

"Confidential Information" means any non-public information disclosed by the Employer to the Employee in connection with their employment, including but not limited to: business strategies, client lists, financial data, trade secrets, technical information, and operational processes.

2. OBLIGATIONS

The Employee agrees to hold all Confidential Information in strict confidence, not disclose it to any third party without prior written consent, and use it solely for performing their employment duties.

3. EXCEPTIONS

This Agreement does not apply to information that is publicly available through no breach of this Agreement, was lawfully in the Employee''s possession prior to disclosure, or is required to be disclosed by law.

4. RETURN OF INFORMATION

Upon termination of employment, the Employee will promptly return all materials containing Confidential Information.

5. DURATION

This Agreement remains in effect during employment and for {{nda_duration_years}} years following termination.

SIGNATURES

Employee: _______________________________  Date: ___________
{{employee_full_name}}

Employer: _______________________________  Date: ___________
{{employer_signatory_name}}, {{employer_signatory_title}}',
  '{"ON":"This Agreement is governed by the laws of the Province of Ontario.","BC":"This Agreement is governed by the laws of the Province of British Columbia.","AB":"This Agreement is governed by the laws of the Province of Alberta.","QC":"La presente convention est regie par les lois de la Province de Quebec."}'::jsonb,
  '[{"key":"employer_name","label":"Employer Name","required":true},{"key":"employee_full_name","label":"Employee Full Name","required":true},{"key":"start_date","label":"Agreement Date","required":true},{"key":"nda_duration_years","label":"Post-Employment Duration (Years)","required":true},{"key":"employer_signatory_name","label":"Signatory Name","required":true},{"key":"employer_signatory_title","label":"Signatory Title","required":true}]'::jsonb,
  true, true, '1.0'
),
(
  NULL, 'probation_notice', 'Probation Period Notice',
  'Formal notice confirming probation period terms and expectations. Given to the employee on or before their first day.',
  'PROBATIONARY PERIOD NOTICE

To: {{employee_full_name}}
Position: {{position_title}}
Start Date: {{start_date}}
Probation End Date: {{probation_end_date}}

Dear {{employee_full_name}},

This letter confirms that your employment as {{position_title}} with {{employer_name}} is subject to a probationary period of {{probation_period}} commencing {{start_date}} and ending {{probation_end_date}}.

During the probationary period, your performance, conduct, and suitability for the role will be assessed. Either party may terminate employment during the probationary period with one week''s written notice.

Upon successful completion of your probationary period, you will become a regular employee as of {{probation_end_date}}.

ACKNOWLEDGEMENT

Employee: _______________________________  Date: ___________
{{employee_full_name}}

HR / Manager: __________________________  Date: ___________
{{employer_signatory_name}}',
  '{"ON":"This notice is provided in accordance with the Employment Standards Act, 2000 (Ontario). The probationary period does not exceed the statutory maximum of 3 months (90 days).","BC":"This notice is provided in accordance with the Employment Standards Act (British Columbia). The probationary period does not exceed 3 months.","AB":"This notice is provided in accordance with the Employment Standards Code (Alberta). The probationary period does not exceed 3 months (90 days).","QC":"Cet avis est fourni conformement a la Loi sur les normes du travail (Quebec). La periode de probation est raisonnable et ne depasse generalement pas 3 mois."}'::jsonb,
  '[{"key":"employer_name","label":"Employer Name","required":true},{"key":"employee_full_name","label":"Employee Full Name","required":true},{"key":"position_title","label":"Position Title","required":true},{"key":"start_date","label":"Start Date","required":true},{"key":"probation_period","label":"Probation Period Description","required":true},{"key":"probation_end_date","label":"Probation End Date","required":true},{"key":"employer_signatory_name","label":"HR/Manager Signatory Name","required":true}]'::jsonb,
  true, true, '1.0'
)
ON CONFLICT DO NOTHING;
