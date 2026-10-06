// backend/routes/projects.js
const express = require('express');
const Project = require('../models/Project');
const Connection = require('../models/Connection');
const authMiddleware = require('../middleware/authMiddleware');
const { parseGithubRepoUrl, fetchRecentCommits } = require('../utils/github');

const router = express.Router();

function serializeProject(project) {
  return {
    id: project._id,
    name: project.name,
    members: (project.memberIds || [])
      .filter((member) => member && member.name)
      .map((member) => ({
        id: member._id,
        name: member.name,
        avatarColor: member.avatarColor,
        age: member.age,
        bio: member.bio
      })),
    repoUrl: project.repoUrl,
    createdAt: project.createdAt
  };
}

async function assertAcceptedConnections(ownerId, memberIds) {
  if (!memberIds || memberIds.length === 0) return true;

  const acceptedCount = await Connection.countDocuments({
    status: 'accepted',
    $or: memberIds.map((memberId) => ({
      $or: [
        { senderId: ownerId, receiverId: memberId },
        { senderId: memberId, receiverId: ownerId }
      ]
    }))
  });

  return acceptedCount === memberIds.length;
}

// GET /api/projects — all of the current user's projects
router.get('/', authMiddleware, async (req, res) => {
  try {
    const projects = await Project.find({ owner: req.user.id })
      .populate('memberIds', 'name avatarColor age bio')
      .sort({ createdAt: -1 });

    res.json({ projects: projects.map(serializeProject) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching projects' });
  }
});

// POST /api/projects — create a project from a set of accepted connections
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name, memberIds, repoUrl } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'name is required' });
    }

    if (repoUrl && !parseGithubRepoUrl(repoUrl)) {
      return res.status(400).json({ message: 'repoUrl must be a valid github.com repository URL' });
    }

    const members = Array.isArray(memberIds) ? memberIds : [];
    const allAccepted = await assertAcceptedConnections(req.user.id, members);
    if (!allAccepted) {
      return res.status(400).json({ message: 'You can only add accepted connections to a project' });
    }

    const project = new Project({
      owner: req.user.id,
      name: name.trim(),
      memberIds: members,
      repoUrl: repoUrl ? repoUrl.trim() : null
    });
    await project.save();
    await project.populate('memberIds', 'name avatarColor age bio');

    res.status(201).json({ project: serializeProject(project) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while creating project' });
  }
});

// PUT /api/projects/:projectId — rename and/or change members
router.put('/:projectId', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.params;
    const { name, memberIds, repoUrl } = req.body;

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }
    if (project.owner.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to edit this project' });
    }

    if (repoUrl !== undefined) {
      if (repoUrl && !parseGithubRepoUrl(repoUrl)) {
        return res.status(400).json({ message: 'repoUrl must be a valid github.com repository URL' });
      }
      project.repoUrl = repoUrl ? repoUrl.trim() : null;
    }

    if (name !== undefined) {
      if (!name.trim()) {
        return res.status(400).json({ message: 'name cannot be empty' });
      }
      project.name = name.trim();
    }

    if (memberIds !== undefined) {
      const members = Array.isArray(memberIds) ? memberIds : [];
      const allAccepted = await assertAcceptedConnections(req.user.id, members);
      if (!allAccepted) {
        return res.status(400).json({ message: 'You can only add accepted connections to a project' });
      }
      project.memberIds = members;
    }

    await project.save();
    await project.populate('memberIds', 'name avatarColor age bio');

    res.json({ project: serializeProject(project) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while updating project' });
  }
});

// GET /api/projects/:projectId/commits — recent push activity on the linked repo
router.get('/:projectId/commits', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }
    if (project.owner.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to view this project' });
    }
    if (!project.repoUrl) {
      return res.status(400).json({ message: 'This project has no linked repo yet' });
    }

    const parsed = parseGithubRepoUrl(project.repoUrl);
    if (!parsed) {
      return res.status(400).json({ message: 'Linked repo URL is invalid' });
    }

    const commits = await fetchRecentCommits(parsed.owner, parsed.repo);
    res.json({ commits });
  } catch (err) {
    console.error(err);
    res.status(502).json({ message: err.message || 'Failed to fetch commits from GitHub' });
  }
});

// DELETE /api/projects/:projectId
router.delete('/:projectId', authMiddleware, async (req, res) => {
  try {
    const { projectId } = req.params;

    const project = await Project.findById(projectId);
    if (!project) {
      return res.status(404).json({ message: 'Project not found' });
    }
    if (project.owner.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to delete this project' });
    }

    await project.deleteOne();

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while deleting project' });
  }
});

module.exports = router;
