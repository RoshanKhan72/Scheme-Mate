-- Seed government schemes mock data
INSERT INTO schemes (name, description, state, category, eligibility_rules, required_documents, benefits, official_website, application_link, application_mode, status, source_type, official_department, start_date, end_date, beneficiary_types, tags, version_number)
VALUES (
    'Post Matric Scholarship Karnataka',
    'Financial assistance for post-matric studies to students belonging to backward classes and minorities.',
    'Karnataka',
    'Education',
    '{"state": "Karnataka", "minAge": 15, "maxAge": 30, "maxIncome": 250000, "isStudent": true, "education": ["PUC", "Diploma", "Undergraduate", "Postgraduate"]}',
    '{"Aadhaar", "Income Certificate", "Caste Certificate"}',
    'Tuition fee reimbursement up to ₹25,000 per annum and maintenance allowance of ₹500 per month.',
    'https://ssp.postmatric.karnataka.gov.in',
    'https://ssp.postmatric.karnataka.gov.in/apply',
    'Online',
    'Open',
    'State Government',
    'Department of Backward Classes Welfare',
    '2026-06-01',
    '2026-09-30',
    '{"Student", "Youth"}',
    '{"scholarship", "education", "karnataka"}',
    1
) ON CONFLICT DO NOTHING;

INSERT INTO schemes (name, description, state, category, eligibility_rules, required_documents, benefits, official_website, application_link, application_mode, status, source_type, official_department, start_date, end_date, beneficiary_types, tags, version_number)
VALUES (
    'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
    'Central sector scheme to provide income support to all landholding farmer families across the country.',
    'All India',
    'Agriculture',
    '{"isFarmer": true, "maxIncome": 500000}',
    '{"Aadhaar", "Land Ownership Record"}',
    'Direct income support of ₹6,000 per year in three equal installments of ₹2,000 directly into bank accounts.',
    'https://pmkisan.gov.in',
    'https://pmkisan.gov.in/newregistration',
    'Online',
    'Open',
    'Central Government',
    'Ministry of Agriculture and Farmers Welfare',
    '2026-01-01',
    '2026-12-31',
    '{"Farmer"}',
    '{"agriculture", "farmer", "income"}',
    1
) ON CONFLICT DO NOTHING;
