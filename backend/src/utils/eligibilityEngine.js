/**
 * Helper to calculate user's age from birthdate
 */
function calculateAge(dobString) {
  const dob = new Date(dobString);
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const m = today.getMonth() - dob.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age;
}

/**
 * Core Rule-Based Eligibility Engine Solver
 * 
 * Evaluates a user's eligibility profile against a scheme's rules and required documents.
 * 
 * @param {object} profile - User eligibility profile record
 * @param {object} scheme - Scheme database record
 * @returns {object} Eligibility Result containing status, matchScore, confidence, checks, and missingFields.
 */
function evaluateSchemeEligibility(profile, scheme) {
  const rules = scheme.eligibility_rules || {};
  const requiredDocs = scheme.required_documents || [];
  
  const checks = [];
  const missingFields = [];
  
  let totalRules = 0;
  let passedRules = 0;
  let hasHardFail = false;
  let hasMissingParam = false;

  // If no profile exists at all, mark status as Unknown with low confidence
  if (!profile) {
    return {
      status: 'Unknown',
      matchScore: 0,
      confidence: 30,
      checks: [],
      missingFields: ['Setup your profile details to calculate eligibility.'],
    };
  }

  // --- DEMOGRAPHIC / GEOGRAPHIC / ECONOMIC RULES EVALUATION ---

  // 1. STATE Check
  if (rules.state && rules.state !== 'All India') {
    totalRules++;
    if (!profile.state) {
      hasMissingParam = true;
      missingFields.push('State');
      checks.push({ ruleId: 'STATE', passed: null, message: 'Missing profile state parameters.' });
    } else if (rules.state.toLowerCase() === profile.state.toLowerCase()) {
      passedRules++;
      checks.push({ ruleId: 'STATE', passed: true, message: `Resident state matches: ${rules.state}.` });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'STATE', passed: false, message: `Restricted to residents of ${rules.state} (User resides in ${profile.state}).` });
    }
  }

  // 2. AGE Checks (DOB)
  const age = calculateAge(profile.dob);
  
  if (rules.minAge) {
    totalRules++;
    if (age < rules.minAge) {
      hasHardFail = true;
      checks.push({ ruleId: 'AGE_MIN', passed: false, message: `Minimum age required is ${rules.minAge} years (User is ${age} years old).` });
    } else {
      passedRules++;
      checks.push({ ruleId: 'AGE_MIN', passed: true, message: `Passed minimum age bounds check.` });
    }
  }

  if (rules.maxAge) {
    totalRules++;
    if (age > rules.maxAge) {
      hasHardFail = true;
      checks.push({ ruleId: 'AGE_MAX', passed: false, message: `Maximum age allowed is ${rules.maxAge} years (User is ${age} years old).` });
    } else {
      passedRules++;
      checks.push({ ruleId: 'AGE_MAX', passed: true, message: `Passed maximum age bounds check.` });
    }
  }

  // 3. INCOME Check
  if (rules.maxIncome) {
    totalRules++;
    const income = parseFloat(profile.annual_income);
    if (isNaN(income) || income === 0) {
      hasMissingParam = true;
      missingFields.push('Annual Family Income');
      checks.push({ ruleId: 'INCOME', passed: null, message: 'Missing profile income details.' });
    } else if (income <= rules.maxIncome) {
      passedRules++;
      checks.push({ ruleId: 'INCOME', passed: true, message: `Annual family income (₹${income}) is below max allowed limit (₹${rules.maxIncome}).` });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'INCOME', passed: false, message: `Annual family income (₹${income}) exceeds maximum allowed threshold (₹${rules.maxIncome}).` });
    }
  }

  // 4. GENDER Check
  if (rules.gender && rules.gender !== 'All') {
    totalRules++;
    if (!profile.gender || profile.gender === 'Select') {
      hasMissingParam = true;
      missingFields.push('Gender');
      checks.push({ ruleId: 'GENDER', passed: null, message: 'Missing profile gender parameter.' });
    } else if (rules.gender.toLowerCase() === profile.gender.toLowerCase()) {
      passedRules++;
      checks.push({ ruleId: 'GENDER', passed: true, message: `Gender aligns with eligibility limits.` });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'GENDER', passed: false, message: `Restricted to ${rules.gender} applicants (User gender is ${profile.gender}).` });
    }
  }

  // 5. CASTE CATEGORY Check
  if (rules.category && Array.isArray(rules.category)) {
    totalRules++;
    if (!profile.category || profile.category === 'Select Category') {
      hasMissingParam = true;
      missingFields.push('Social Category');
      checks.push({ ruleId: 'CATEGORY', passed: null, message: 'Missing profile category selection.' });
    } else {
      const allowedCategories = rules.category.map(c => c.toLowerCase());
      if (allowedCategories.includes(profile.category.toLowerCase())) {
        passedRules++;
        checks.push({ ruleId: 'CATEGORY', passed: true, message: `Social category (${profile.category}) matches permitted classes.` });
      } else {
        hasHardFail = true;
        checks.push({ ruleId: 'CATEGORY', passed: false, message: `Restricted to categories: ${rules.category.join(', ')} (User category is ${profile.category}).` });
      }
    }
  }

  // 6. EDUCATION Check
  if (rules.education && Array.isArray(rules.education)) {
    totalRules++;
    if (!profile.education || profile.education === 'Select Education') {
      hasMissingParam = true;
      missingFields.push('Education level');
      checks.push({ ruleId: 'EDUCATION', passed: null, message: 'Missing profile education parameters.' });
    } else {
      const allowedEdus = rules.education.map(e => e.toLowerCase());
      if (allowedEdus.includes(profile.education.toLowerCase())) {
        passedRules++;
        checks.push({ ruleId: 'EDUCATION', passed: true, message: `Education level matches required standards.` });
      } else {
        hasHardFail = true;
        checks.push({ ruleId: 'EDUCATION', passed: false, message: `Requires qualifications: ${rules.education.join(', ')} (User holds ${profile.education}).` });
      }
    }
  }

  // 7. OCCUPATION Flags Checks
  if (rules.isStudent === true) {
    totalRules++;
    if (profile.is_student === true) {
      passedRules++;
      checks.push({ ruleId: 'STUDENT', passed: true, message: 'Verified active enrolment as a Student.' });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'STUDENT', passed: false, message: 'User profile does not indicate active student status.' });
    }
  }

  if (rules.isFarmer === true) {
    totalRules++;
    if (profile.is_farmer === true) {
      passedRules++;
      checks.push({ ruleId: 'FARMER', passed: true, message: 'Verified landholding Farmer status.' });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'FARMER', passed: false, message: 'User profile does not indicate agricultural farmer status.' });
    }
  }

  if (rules.isBusinessOwner === true) {
    totalRules++;
    if (profile.is_business_owner === true) {
      passedRules++;
      checks.push({ ruleId: 'BUSINESS', passed: true, message: 'Verified Business Owner status.' });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'BUSINESS', passed: false, message: 'User profile does not indicate business owner status.' });
    }
  }

  // 8. DISABILITY Check
  if (rules.disabilityStatus === true) {
    totalRules++;
    if (profile.disability_status === true) {
      passedRules++;
      checks.push({ ruleId: 'DISABILITY', passed: true, message: 'Verified disability eligibility.' });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'DISABILITY', passed: false, message: 'Requires verified physical/mental disability status.' });
    }
  }

  // 9. MINORITY Check
  if (rules.minorityStatus === true) {
    totalRules++;
    if (profile.minority_status === true) {
      passedRules++;
      checks.push({ ruleId: 'MINORITY', passed: true, message: 'Verified minority community credentials.' });
    } else {
      hasHardFail = true;
      checks.push({ ruleId: 'MINORITY', passed: false, message: 'Requires notified minority status.' });
    }
  }

  // --- REQUIRED DOCUMENTS CHECK ---
  let hasMissingDocument = false;
  const userDocs = profile.documents || {};

  for (const doc of requiredDocs) {
    totalRules++;
    const ruleId = `DOC_${doc.replace(/\s+/g, '_').toUpperCase()}`;
    const userDocInfo = userDocs[doc];

    if (userDocInfo && userDocInfo.exists === true) {
      passedRules++;
      checks.push({ ruleId, passed: true, message: `Document available: ${doc}.` });
    } else {
      hasMissingDocument = true;
      missingFields.push(`${doc} certificate`);
      checks.push({ ruleId, passed: false, message: `Missing required document: ${doc}.` });
    }
  }

  // --- SOLVER OUTPUT METRICS RESOLUTION ---

  // Calculate Match Score percentage (passed rules / total checked rules)
  const matchScore = totalRules > 0 ? Math.round((passedRules / totalRules) * 100) : 100;

  // Calculate Confidence score (penalized by missing parameter indicators)
  const missingRulesCount = checks.filter(c => c.passed === null).length;
  const confidence = totalRules > 0 
      ? Math.round(((totalRules - missingRulesCount) / totalRules) * 100)
      : 100;

  // Resolve Overall status
  let status = 'Eligible';
  if (hasHardFail) {
    status = 'Not Eligible';
  } else if (hasMissingParam) {
    status = 'Unknown';
  } else if (hasMissingDocument) {
    status = 'Partially Eligible';
  }

  return {
    status,
    matchScore,
    confidence,
    checks,
    missingFields,
  };
}

module.exports = {
  evaluateSchemeEligibility,
};
