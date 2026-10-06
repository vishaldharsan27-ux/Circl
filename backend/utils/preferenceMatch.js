// backend/utils/preferenceMatch.js
// What a user expects out of a connection (Build a project / Learn together /
// Mentor someone / Hire-recruit for a project), checked against the other
// user's own pick. Same-goal pairs match, plus two natural cross pairs:
// a builder recruiting help matches someone looking to hire, and a learner
// matches a mentor.
const COMPATIBLE_PREFERENCES = {
  Build: ['Build', 'Hire'],
  Hire: ['Hire', 'Build'],
  Learn: ['Learn', 'Mentor'],
  Mentor: ['Mentor', 'Learn']
};

function isPreferenceCompatible(preferenceA, preferenceB) {
  if (!preferenceA || !preferenceB) return false;
  return COMPATIBLE_PREFERENCES[preferenceA]?.includes(preferenceB) ?? false;
}

module.exports = { COMPATIBLE_PREFERENCES, isPreferenceCompatible };
