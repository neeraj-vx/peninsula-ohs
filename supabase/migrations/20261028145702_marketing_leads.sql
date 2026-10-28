-- =============================================================
-- Contact-form submissions from the public marketing site.
-- Written only by the server (service role) after validation;
-- no access for anon or signed-in users.
-- =============================================================

CREATE TABLE public.marketing_leads (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 200),
  email          text NOT NULL CHECK (char_length(email) BETWEEN 3 AND 320),
  company        text CHECK (char_length(company) <= 200),
  province       text CHECK (char_length(province) <= 2),
  employee_count text CHECK (char_length(employee_count) <= 50),
  interest       text CHECK (char_length(interest) <= 100),
  message        text CHECK (char_length(message) <= 5000),
  source_page    text CHECK (char_length(source_page) <= 200),
  status         text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'closed')),
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_marketing_leads_created ON public.marketing_leads (created_at DESC);

ALTER TABLE public.marketing_leads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.marketing_leads FROM anon, authenticated;
COMMENT ON TABLE public.marketing_leads IS 'Marketing contact form submissions; service role only';
