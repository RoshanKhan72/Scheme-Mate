const test = require('node:test');
const assert = require('node:assert');
const eligibilityEngine = require('../../src/utils/eligibilityEngine');

test('Eligibility Engine - Unit Tests Suite', async (t) => {
  
  await t.test('Profile matching central and state rules correctly', () => {
    const mockProfile = {
      dob: '2005-08-15', // Age 20 in 2026
      gender: 'Male',
      state: 'Karnataka',
      district: 'Davanagere',
      annual_income: 180000,
      is_student: true,
      is_farmer: false,
      is_business_owner: false,
      category: 'OBC',
      documents: {
        'Aadhaar': { exists: true },
        'Income Certificate': { exists: true },
        'Caste Certificate': { exists: true }
      }
    };

    const mockScheme = {
      name: 'Post Matric Scholarship',
      state: 'Karnataka',
      eligibility_rules: {
        state: 'Karnataka',
        minAge: 18,
        maxAge: 35,
        maxIncome: 250000,
        isStudent: true,
        category: ['OBC', 'SC', 'ST']
      },
      required_documents: ['Aadhaar', 'Income Certificate', 'Caste Certificate']
    };

    const res = eligibilityEngine.evaluateSchemeEligibility(mockProfile, mockScheme);
    
    assert.strictEqual(res.status, 'Eligible');
    assert.strictEqual(res.matchScore, 100);
    assert.strictEqual(res.confidence, 100);
    assert.strictEqual(res.checks.every(c => c.passed), true);
  });

  await t.test('Reject profile mismatching residency constraints', () => {
    const mockProfile = {
      dob: '2001-01-01', // Age 25
      state: 'Maharashtra',
      annual_income: 120000,
      is_student: true,
      category: 'General',
      documents: {}
    };

    const mockScheme = {
      name: 'Karnataka Youth Scheme',
      state: 'Karnataka',
      eligibility_rules: {
        state: 'Karnataka'
      },
      required_documents: []
    };

    const res = eligibilityEngine.evaluateSchemeEligibility(mockProfile, mockScheme);
    
    assert.strictEqual(res.status, 'Not Eligible');
    assert.ok(res.checks.some(c => c.ruleId === 'STATE' && c.passed === false));
  });

  await t.test('Report Partially Eligible if documents are missing', () => {
    const mockProfile = {
      dob: '2006-01-01', // Age 20
      state: 'Karnataka',
      annual_income: 120000,
      is_student: true,
      category: 'SC',
      documents: {
        'Aadhaar': { exists: true }
        // Missing Caste Certificate
      }
    };

    const mockScheme = {
      name: 'SC Scholarship',
      state: 'Karnataka',
      eligibility_rules: {
        state: 'Karnataka',
        category: ['SC']
      },
      required_documents: ['Aadhaar', 'Caste Certificate']
    };

    const res = eligibilityEngine.evaluateSchemeEligibility(mockProfile, mockScheme);
    
    assert.strictEqual(res.status, 'Partially Eligible');
    assert.ok(res.checks.some(c => c.ruleId.startsWith('DOC_') && c.passed === false));
  });
});
