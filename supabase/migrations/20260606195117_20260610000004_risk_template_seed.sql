-- Gap 5: Seed 25 system risk templates
-- risk_number supplied explicitly to bypass generate_risk_number trigger (fails when org IS NULL)
-- source_type = 'standalone', review_frequency = 'annually' per check constraints
INSERT INTO risks (
  organisation_id, is_template, template_industry, title,
  hazard_description, people_at_risk,
  likelihood_score, consequence_score, inherent_risk_level,
  existing_controls_summary,
  residual_likelihood_score, residual_consequence_score, residual_risk_level,
  status, source_type, review_frequency, risk_number
)
VALUES
-- GENERAL (7)
(NULL, true, 'general', 'Manual Handling - Lifting and Carrying',
 'Workers lifting or carrying heavy or awkward loads may suffer musculoskeletal injuries including back strain, shoulder injuries, and hernias.',
 ARRAY['All workers performing physical tasks'], 3, 3, 'medium',
 'Training on safe lifting techniques. Use of mechanical aids (trolleys, forklifts) for loads >15kg. Team lifting for loads >25kg. Regular task rotation.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-GEN-001'),

(NULL, true, 'general', 'Slip, Trip and Fall - Same Level',
 'Workers walking on wet, slippery, uneven, or cluttered surfaces may slip, trip or fall causing soft tissue injuries, fractures, or head injuries.',
 ARRAY['All personnel on site'], 3, 2, 'medium',
 'Good housekeeping procedures. Non-slip flooring and footwear. Spill clean-up procedures. Adequate lighting. Regular inspections.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-GEN-002'),

(NULL, true, 'general', 'Electrical Hazards - General',
 'Contact with live electrical equipment, damaged wiring, or overloaded circuits may cause electric shock, burns, cardiac arrest, or fire.',
 ARRAY['All workers, maintenance staff, electricians'], 2, 5, 'high',
 'Qualified electricians only for electrical work. Lockout/tagout procedures. Regular inspection and testing of equipment. RCD protection. No DIY electrical repairs.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-GEN-003'),

(NULL, true, 'general', 'Chemical Exposure - Hazardous Substances',
 'Inhalation, skin contact, or ingestion of hazardous chemicals (cleaning agents, solvents, paints) may cause acute or chronic health effects.',
 ARRAY['Workers using or near chemicals'], 3, 3, 'medium',
 'SDS available for all chemicals. Appropriate PPE (gloves, goggles, respirator). Adequate ventilation. Substitution with less hazardous alternatives where possible.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-GEN-004'),

(NULL, true, 'general', 'Fire and Explosion Risk',
 'Ignition of flammable materials, gas leaks, or electrical faults may cause fire or explosion resulting in burns, smoke inhalation, or fatalities.',
 ARRAY['All site personnel'], 2, 5, 'high',
 'Fire detection and suppression systems. No smoking policy. Proper storage of flammables. Emergency evacuation plan and drills. Regular fire equipment inspections.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-GEN-005'),

(NULL, true, 'general', 'Working at Heights (General)',
 'Falls from ladders, platforms, roofs, or elevated work areas may cause serious injury or death.',
 ARRAY['Workers performing tasks above 2 metres'], 2, 5, 'high',
 'Fall prevention hierarchy: eliminate task at height, use scaffolding, use EWP, use safety nets, use harness. Regular equipment inspection. Competency training. Edge protection.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-GEN-006'),

(NULL, true, 'general', 'Fatigue and Mental Health',
 'Excessive working hours, shift work, high workload, or workplace stress may lead to fatigue, burnout, and mental health conditions affecting safety and performance.',
 ARRAY['All workers, especially shift workers and managers'], 3, 3, 'medium',
 'Maximum hours and shift rotation policy. Fatigue management training. Mental health first aiders. Employee Assistance Program. Regular workload reviews.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-GEN-007'),

-- CONSTRUCTION (5)
(NULL, true, 'construction', 'Excavation and Trenching Collapse',
 'Unsupported excavations or trenches may collapse, burying workers and causing crush injuries or asphyxiation.',
 ARRAY['Workers in or near excavations'], 2, 5, 'high',
 'Competent person inspection before entry. Shoring, battering, or benching for trenches >1.5m. No entry without authorisation. Spoil placed minimum 0.6m from edge. Emergency rescue plan.',
 1, 5, 'high', 'active', 'standalone', 'annually', 'TMPL-CON-001'),

(NULL, true, 'construction', 'Struck by Falling Objects',
 'Tools, materials, or debris dropped from heights may strike workers below causing head injuries, fractures, or fatalities.',
 ARRAY['Workers below elevated work areas, pedestrians'], 3, 4, 'high',
 'Exclusion zones below elevated work. Toe boards on scaffolding. Tool lanyards. Hard hat requirement. Netting and catch platforms. Tool boxes at height.',
 2, 3, 'medium', 'active', 'standalone', 'annually', 'TMPL-CON-002'),

(NULL, true, 'construction', 'Plant and Heavy Equipment',
 'Contact with moving plant (excavators, forklifts, trucks) may cause crush injuries, amputations, or fatalities.',
 ARRAY['Workers and pedestrians near plant'], 2, 5, 'high',
 'Traffic management plan. Segregation of plant and pedestrian areas. Spotters for reversing. Exclusion zones. Competency checks for operators. Pre-start inspections.',
 1, 5, 'high', 'active', 'standalone', 'annually', 'TMPL-CON-003'),

(NULL, true, 'construction', 'Confined Space Entry',
 'Entering confined spaces (pits, tanks, sewers) without proper controls may expose workers to toxic atmospheres, oxygen deficiency, or engulfment.',
 ARRAY['Workers required to enter confined spaces'], 1, 5, 'high',
 'Confined space permit system. Atmospheric testing before and during entry. Trained standby person. Rescue equipment on site. Mechanical ventilation. Communication systems.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-CON-004'),

(NULL, true, 'construction', 'Noise-Induced Hearing Loss',
 'Prolonged exposure to high noise levels from power tools, machinery, and compressors may cause permanent hearing damage.',
 ARRAY['All workers on construction sites'], 4, 2, 'medium',
 'Noise assessment. Engineering controls (quieter equipment, enclosures). Administrative controls (rotation, scheduling). Hearing protection zones. Audiometric testing program.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-CON-005'),

-- RETAIL (5)
(NULL, true, 'retail', 'Customer Aggression and Violence',
 'Verbal abuse, threats, or physical assault from customers may cause psychological harm and physical injury to staff.',
 ARRAY['Customer-facing staff, especially lone workers'], 3, 3, 'medium',
 'De-escalation training. Duress alarms and CCTV. Clear aggression policy. Incident reporting system. Support for affected staff (EAP). Security personnel at high-risk times.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-RET-001'),

(NULL, true, 'retail', 'Lone Worker Safety',
 'Staff working alone (opening/closing, after hours, delivery acceptance) face increased risk with no immediate assistance available.',
 ARRAY['Staff working alone or in isolated areas'], 3, 3, 'medium',
 'Lone worker check-in procedures. Personal duress devices. Time-based check-ins with manager. Clear emergency contact procedures. No lone working after hours where possible.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-RET-002'),

(NULL, true, 'retail', 'Manual Handling - Stock and Deliveries',
 'Unloading deliveries, stacking shelves, and moving stock may cause musculoskeletal injuries especially to the back, shoulders, and wrists.',
 ARRAY['Warehouse and shop floor staff'], 3, 3, 'medium',
 'Training on safe lifting. Mechanical aids (trolleys, pallet jacks). Team lifting for heavy items. Shelf height limits. Regular rotation of physically demanding tasks.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-RET-003'),

(NULL, true, 'retail', 'Cash Handling and Robbery',
 'Handling cash at registers or during banking runs creates risk of robbery, which may result in physical harm and significant psychological trauma.',
 ARRAY['Cashiers, managers handling cash'], 2, 4, 'high',
 'Minimise cash on site (electronic payments). Time-delay safes. No set routine for banking. CCTV coverage. Staff not to resist robbery. Post-incident counselling available.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-RET-004'),

(NULL, true, 'retail', 'Slips in Retail Environment',
 'Spills of liquids or produce on retail floors may cause customer and staff slip injuries.',
 ARRAY['All staff and customers'], 4, 2, 'medium',
 'Immediate spill clean-up and wet floor signage. Non-slip matting at entrances. Regular floor inspections. Non-slip footwear requirement for staff. Clear reporting procedure.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-RET-005'),

-- FOOD SERVICE (5)
(NULL, true, 'food_service', 'Burns from Hot Surfaces and Equipment',
 'Contact with hot cooking equipment, surfaces, oils, and steam may cause burns ranging from minor to severe.',
 ARRAY['Kitchen staff, food preparation workers'], 4, 3, 'high',
 'Oven mitts and heat-resistant gloves. Warning labels on hot surfaces. Staff training on burn first aid. Appropriate PPE. Equipment guards and cool-down procedures.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-FSV-001'),

(NULL, true, 'food_service', 'Cuts from Knives and Sharp Equipment',
 'Use of knives, slicers, mandolins, and graters creates risk of lacerations and puncture wounds.',
 ARRAY['Kitchen and food prep staff'], 4, 2, 'medium',
 'Cut-resistant gloves for high-risk tasks. Knife safety training. Secure knife storage. Safe blade disposal procedures. First aid equipment nearby.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-FSV-002'),

(NULL, true, 'food_service', 'Food Allergen Cross-Contamination',
 'Cross-contamination of allergens (nuts, gluten, dairy, eggs) may cause severe allergic reactions including anaphylaxis in customers.',
 ARRAY['Customers with allergies, kitchen staff'], 2, 5, 'high',
 'Allergen training for all staff. Separate equipment for allergen-free meals. Clear menu labelling. Customer allergy declaration process. Epinephrine auto-injectors on site. Supplier allergen declarations.',
 1, 4, 'medium', 'active', 'standalone', 'annually', 'TMPL-FSV-003'),

(NULL, true, 'food_service', 'Slippery Kitchen Floors',
 'Spills of oils, water, and food waste on kitchen floors create high slip risk for staff in a fast-paced environment.',
 ARRAY['Kitchen staff'], 4, 3, 'high',
 'Non-slip flooring. Non-slip footwear requirement. Immediate clean-up of spills. Floor drainage. Regular mopping schedule. Wet floor signs.',
 2, 2, 'low', 'active', 'standalone', 'annually', 'TMPL-FSV-004'),

(NULL, true, 'food_service', 'Cold Room Entrapment',
 'Staff entering cold storage rooms may become entrapped if the door mechanism fails, leading to hypothermia or death.',
 ARRAY['Staff accessing cold and freezer rooms'], 1, 5, 'high',
 'Interior emergency release on all cold room doors. Buddy system for cold room access. Regular door mechanism inspections. Communication device inside cold rooms. Emergency alarm button.',
 1, 3, 'medium', 'active', 'standalone', 'annually', 'TMPL-FSV-005');
