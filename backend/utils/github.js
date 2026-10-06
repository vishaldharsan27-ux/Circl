// backend/utils/github.js
// Public-repo-only push activity: GitHub has no concept of "pulls" server-side
// (a pull is a local operation that never touches GitHub), so this only ever
// surfaces pushes/commits via the public commits API. No auth token — relies
// on GitHub's unauthenticated rate limit (60 requests/hour per IP), which is
// fine for a manual "Refresh" button rather than background polling.
function parseGithubRepoUrl(url) {
  if (!url) return null;
  try {
    const parsed = new URL(url.trim());
    if (!/(^|\.)github\.com$/.test(parsed.hostname)) return null;

    const parts = parsed.pathname.split('/').filter(Boolean);
    if (parts.length < 2) return null;

    const owner = parts[0];
    const repo = parts[1].replace(/\.git$/, '');
    return { owner, repo };
  } catch (_err) {
    return null;
  }
}

async function fetchRecentCommits(owner, repo, limit = 20) {
  const url = `https://api.github.com/repos/${owner}/${repo}/commits?per_page=${limit}`;

  const response = await fetch(url, {
    headers: {
      Accept: 'application/vnd.github+json',
      'User-Agent': 'circl-app'
    }
  });

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Repository not found or is private');
    }
    if (response.status === 403) {
      throw new Error('GitHub API rate limit exceeded, try again later');
    }
    throw new Error(`GitHub API error (${response.status})`);
  }

  const data = await response.json();

  return data.map((commit) => ({
    sha: commit.sha.slice(0, 7),
    message: (commit.commit?.message || '').split('\n')[0],
    authorName: commit.commit?.author?.name || commit.author?.login || 'Unknown',
    authorLogin: commit.author?.login || null,
    authorAvatarUrl: commit.author?.avatar_url || null,
    date: commit.commit?.author?.date || null,
    url: commit.html_url
  }));
}

module.exports = { parseGithubRepoUrl, fetchRecentCommits };
