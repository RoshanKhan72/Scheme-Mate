const profileModel = require('../models/profileModel');
const schemeModel = require('../models/schemeModel');
const eligibilityEngine = require('../utils/eligibilityEngine');

/**
 * Calculates user profile completion score dynamically on the backend
 */
function calculateProfileCompletion(profile) {
  if (!profile) return 0;
  
  const fields = [
    profile.dob,
    profile.gender,
    profile.state,
    profile.district,
    profile.village_city,
    profile.occupation,
    profile.education,
    profile.marital_status,
    profile.annual_income !== null && profile.annual_income !== undefined && parseFloat(profile.annual_income) !== 0
  ];
  
  const filled = fields.filter(f => f !== null && f !== undefined && f !== '' && f !== 'Select' && f !== false).length;
  return Math.round((filled / fields.length) * 100);
}

/**
 * Compiles dashboard metrics, counts, and lightweight feed subsets
 * 
 * @param {string} userId - User UUID
 * @returns {object} Compiled dashboard summary
 */
async function getDashboardSummary(userId) {
  // 1. Database Lookups: Consolidated to exactly 2 queries for optimal performance
  const profile = await profileModel.getProfileByUserId(userId);
  const schemes = await schemeModel.getAllSchemes();

  // Calculate profile metrics
  const profileCompletion = calculateProfileCompletion(profile);
  const lastUpdated = profile ? profile.updated_at : null;

  // 2. Evaluate eligibility on each scheme in-memory (O(N) CPU operations)
  const evaluatedSchemes = schemes.map(scheme => {
    const result = eligibilityEngine.evaluateSchemeEligibility(profile, scheme);
    return {
      ...scheme,
      eligibilityResult: result,
    };
  });

  // 3. Partition schemes by matched status types
  const eligible = evaluatedSchemes.filter(s => s.eligibilityResult.status === 'Eligible');
  const partiallyEligible = evaluatedSchemes.filter(s => s.eligibilityResult.status === 'Partially Eligible');
  const unknown = evaluatedSchemes.filter(s => s.eligibilityResult.status === 'Unknown');

  // Compile missing documents checklist across partially eligible schemes to create actionable tasks
  const missingDocsSet = new Set();
  partiallyEligible.forEach(s => {
    s.eligibilityResult.checks.forEach(check => {
      if (check.ruleId.startsWith('DOC_') && check.passed === false) {
        // Extract document display name from checklist message (e.g. "Missing required document: Aadhaar")
        const docName = check.message.replace('Missing required document: ', '').replace('.', '');
        missingDocsSet.add(docName);
      }
    });
  });
  const missingDocuments = Array.from(missingDocsSet);

  // 4. Feeds Compilation: Lightweight slices limited to exactly 3 items for performance

  // Feed A: Recommended (All-pass Eligible schemes)
  const recommendedFeed = eligible.slice(0, 3);

  // Feed B: New Schemes (Recently created in DB)
  const sortedByDate = [...evaluatedSchemes].sort(
    (a, b) => new Date(b.created_at) - new Date(a.created_at)
  );
  const newSchemesFeed = sortedByDate.slice(0, 3);

  // Feed C: Trending Schemes (Sorted by views_count descending)
  const sortedByPopularity = [...evaluatedSchemes].sort(
    (a, b) => b.views_count - a.views_count
  );
  const trendingFeed = sortedByPopularity.slice(0, 3);

  // Feed D: Closing Soon (Active schemes sorted by nearest end date)
  const today = new Date();
  const closingSoonFeed = evaluatedSchemes
    .filter(s => s.end_date && new Date(s.end_date) >= today && s.status === 'Open')
    .sort((a, b) => new Date(a.end_date) - new Date(b.end_date))
    .slice(0, 3);

  return {
    profileCompletion,
    lastUpdated,
    eligibleCount: eligible.length,
    partiallyEligibleCount: partiallyEligible.length,
    missingDocumentsCount: missingDocuments.length,
    missingDocuments,
    feeds: {
      recommended: recommendedFeed,
      newSchemes: newSchemesFeed,
      trending: trendingFeed,
      closingSoon: closingSoonFeed,
    },
  };
}

module.exports = {
  getDashboardSummary,
};
