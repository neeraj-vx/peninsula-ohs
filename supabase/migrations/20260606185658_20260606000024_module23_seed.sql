-- PPE Issuance Tracking Module — Seed Data
-- Add missing columns if they don't exist
ALTER TABLE ppe_types ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'general';
ALTER TABLE ppe_types ADD COLUMN IF NOT EXISTS standard_reference TEXT;

-- Update existing rows with category and standard_reference data
UPDATE ppe_types SET category = 'head',             standard_reference = 'AS/NZS 1801' WHERE code = 'hard_hat'           AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'body',             standard_reference = 'AS/NZS 4602' WHERE code = 'safety_vest'        AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'feet',             standard_reference = 'AS/NZS 2210' WHERE code = 'safety_boots'       AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'hands',            standard_reference = 'AS/NZS 2161' WHERE code = 'safety_gloves'      AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'eyes',             standard_reference = 'AS/NZS 1337' WHERE code = 'safety_glasses'     AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'ears',             standard_reference = 'AS/NZS 1270' WHERE code = 'hearing_protection' AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'respiratory',      standard_reference = 'AS/NZS 1716' WHERE code = 'respirator'         AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'fall_protection',  standard_reference = 'AS/NZS 1891' WHERE code = 'safety_harness'     AND (category = 'general' OR category IS NULL);
UPDATE ppe_types SET category = 'face',             standard_reference = 'AS/NZS 1337' WHERE code = 'face_shield'        AND (category = 'general' OR category IS NULL);
