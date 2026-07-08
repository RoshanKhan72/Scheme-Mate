-- SQL Seeds for core Central and Karnataka Government Schemes

-- PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)
INSERT INTO schemes (
    name, description, state, category, eligibility_rules, required_documents, benefits, 
    official_website, application_link, pdf_notification_link, application_mode, status, 
    source_type, official_department, last_verified_date, beneficiary_types, tags, version_number
) VALUES (
    'Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)',
    'A central sector scheme that provides income support to all landholding farmer families across the country to enable them to take care of agricultural expenses.',
    'All India',
    'Agriculture',
    '{"state": "All India", "isFarmer": true, "maxIncome": 99999999}',
    '{"Aadhaar", "Land Ownership Documents", "Bank Account Details"}',
    'Income support of ₹6,000 per year is provided in three equal installments of ₹2,000 directly into the bank accounts of the beneficiaries.',
    'https://pmkisan.gov.in',
    'https://pmkisan.gov.in/RegistrationFormNew.aspx',
    'https://pmkisan.gov.in/Documents/RevisedGuidelines.pdf',
    'Online',
    'Open',
    'Central Government',
    'Department of Agriculture and Farmers Welfare',
    '2026-07-01',
    '{"Farmer"}',
    '{"farmer", "subsidy", "income-support", "pm-kisan"}',
    1
) ON CONFLICT DO NOTHING;

-- Gruha Lakshmi Scheme (Karnataka)
INSERT INTO schemes (
    name, description, state, category, eligibility_rules, required_documents, benefits, 
    official_website, application_link, pdf_notification_link, application_mode, status, 
    source_type, official_department, last_verified_date, beneficiary_types, tags, version_number
) VALUES (
    'Gruha Lakshmi Scheme',
    'A Karnataka state welfare scheme designed to support women heads of households by providing monthly financial assistance to meet household expenses.',
    'Karnataka',
    'Welfare',
    '{"state": "Karnataka", "gender": "Female", "category": ["SC", "ST", "OBC", "General", "EWS", "Other"]}',
    '{"Aadhaar", "Ration Card", "Bank Account Details"}',
    'Monthly financial assistance of ₹2,000 transferred directly to the bank account of the woman head of household.',
    'https://sevasindhu.karnataka.gov.in',
    'https://sevasindhugs.karnataka.gov.in/gs_login',
    'https://sevasindhu.karnataka.gov.in/GruhaLakshmiGuidelines.pdf',
    'Both',
    'Open',
    'State Government',
    'Department of Women and Child Development, Karnataka',
    '2026-07-02',
    '{"Woman"}',
    '{"women", "financial-aid", "karnataka", "household"}',
    1
) ON CONFLICT DO NOTHING;

-- Post Matric Scholarship for SC/ST/OBC Students (Karnataka)
INSERT INTO schemes (
    name, description, state, category, eligibility_rules, required_documents, benefits, 
    official_website, application_link, pdf_notification_link, application_mode, status, 
    source_type, official_department, last_verified_date, beneficiary_types, tags, version_number
) VALUES (
    'Post Matric Scholarship for Students',
    'Financial assistance offered to meritorious students belonging to SC/ST/OBC categories pursuing post-matriculation courses (Class 11, ITI, Diploma, Degrees, Post-graduation) in Karnataka.',
    'Karnataka',
    'Education',
    '{"state": "Karnataka", "isStudent": true, "maxIncome": 250000, "education": ["SSLC", "PUC", "Diploma", "ITI", "Undergraduate", "Postgraduate"]}',
    '{"Aadhaar", "Income Certificate", "Caste Certificate", "Admission Fee Receipt"}',
    'Tuition fee reimbursement, examination fee reimbursement, and maintenance allowance ranging from ₹500 to ₹1,200 per month depending on the course of study.',
    'https://ssp.postmatric.karnataka.gov.in',
    'https://ssp.postmatric.karnataka.gov.in/student_login.aspx',
    'https://ssp.postmatric.karnataka.gov.in/Guidelines2025.pdf',
    'Online',
    'Open',
    'State Government',
    'Social Welfare Department, Karnataka',
    '2026-06-15',
    '{"Student"}',
    '{"student", "scholarship", "college", "sc-st-obc", "education"}',
    1
) ON CONFLICT DO NOTHING;

-- Pradhan Mantri Mudra Yojana (PMMY)
INSERT INTO schemes (
    name, description, state, category, eligibility_rules, required_documents, benefits, 
    official_website, application_link, pdf_notification_link, application_mode, status, 
    source_type, official_department, last_verified_date, beneficiary_types, tags, version_number
) VALUES (
    'Pradhan Mantri Mudra Yojana (PMMY)',
    'A central government scheme that provides collateral-free loans to micro and small enterprises to help them establish, run, or expand business activities.',
    'All India',
    'Business',
    '{"state": "All India", "minAge": 18, "isBusinessOwner": true}',
    '{"Aadhaar", "PAN", "Business Registration Certificate", "Income Statement"}',
    'Collateral-free business loans up to ₹10 Lakhs categorised under three stages: Shishu (loans up to ₹50,000), Kishore (loans above ₹50,000 and up to ₹5 Lakhs), and Tarun (loans above ₹5 Lakhs and up to ₹10 Lakhs).',
    'https://www.mudra.org.in',
    'https://www.udyamimitra.in',
    'https://www.mudra.org.in/Documents/PMMYGuidelines.pdf',
    'Both',
    'Open',
    'Central Government',
    'Ministry of Finance, Government of India',
    '2026-06-20',
    '{"Business Owner"}',
    '{"business", "loans", "startup", "mudra", "collateral-free"}',
    1
) ON CONFLICT DO NOTHING;

-- Indira Gandhi National Old Age Pension Scheme (IGNOAPS)
INSERT INTO schemes (
    name, description, state, category, eligibility_rules, required_documents, benefits, 
    official_website, application_link, pdf_notification_link, application_mode, status, 
    source_type, official_department, last_verified_date, beneficiary_types, tags, version_number
) VALUES (
    'Indira Gandhi National Old Age Pension Scheme (IGNOAPS)',
    'A welfare scheme providing monthly pension support to elderly citizens belonging to households below the poverty line (BPL).',
    'All India',
    'Welfare',
    '{"state": "All India", "minAge": 60, "maxIncome": 200000}',
    '{"Aadhaar", "Age Proof Certificate", "BPL Ration Card", "Bank Account Details"}',
    'A monthly pension of ₹200 for persons between 60-79 years of age, and ₹500 per month for persons aged 80 years and above.',
    'https://nsap.nic.in',
    'https://nsap.nic.in/applyOnline',
    'https://nsap.nic.in/IGNOAPSGUIDELINES.pdf',
    'Offline',
    'Open',
    'Central Government',
    'Ministry of Rural Development',
    '2026-06-10',
    '{"Senior Citizen"}',
    '{"senior", "pension", "bpl", "social-welfare"}',
    1
) ON CONFLICT DO NOTHING;
