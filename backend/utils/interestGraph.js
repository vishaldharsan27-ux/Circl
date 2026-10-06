// backend/utils/interestGraph.js
// Models the fixed 12 interest tags as leaves under 4 category nodes, so two
// users who picked related-but-not-identical tags still get partial credit.
const CATEGORY_MAP = {
  'Gen AI': 'GenAI',
  LLM: 'GenAI',
  SLM: 'GenAI',
  'Agentic AI': 'Applied AI',
  RAG: 'Applied AI',
  LangChain: 'Applied AI',
  'Machine Learning': 'Core ML',
  'Deep Learning': 'Core ML',
  'Computer Vision': 'Core ML',
  MLOps: 'MLOps',
  'Data Engineering': 'MLOps',
  'Cloud/DevOps': 'MLOps'
};

function jaccard(setA, setB) {
  const union = new Set([...setA, ...setB]);
  if (union.size === 0) return 0;
  const intersection = [...setA].filter((item) => setB.has(item));
  return intersection.length / union.size;
}

function calculateMatch(userInterests = [], otherInterests = []) {
  if (!userInterests.length || !otherInterests.length) {
    return { matchPercent: 0, sharedInterests: [], relatedInterests: [] };
  }

  const setA = new Set(userInterests);
  const setB = new Set(otherInterests);
  const tagJaccard = jaccard(setA, setB);

  const catsA = new Set(userInterests.map((tag) => CATEGORY_MAP[tag]).filter(Boolean));
  const catsB = new Set(otherInterests.map((tag) => CATEGORY_MAP[tag]).filter(Boolean));
  const categoryJaccard = jaccard(catsA, catsB);

  const matchPercent = Math.round(100 * (0.7 * tagJaccard + 0.3 * categoryJaccard));

  const sharedInterests = otherInterests.filter((tag) => setA.has(tag));
  const relatedInterests = otherInterests.filter(
    (tag) => !setA.has(tag) && catsA.has(CATEGORY_MAP[tag])
  );

  return { matchPercent, sharedInterests, relatedInterests };
}

module.exports = { CATEGORY_MAP, calculateMatch };
