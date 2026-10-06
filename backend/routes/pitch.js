// backend/routes/pitch.js
const express = require('express');
const User = require('../models/User');
const Connection = require('../models/Connection');
const Pitch = require('../models/Pitch');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

async function requireAcceptedConnection(userIdA, userIdB) {
  return Connection.findOne({
    $or: [
      { senderId: userIdA, receiverId: userIdB },
      { senderId: userIdB, receiverId: userIdA }
    ],
    status: 'accepted'
  });
}

// POST /api/pitch — send a one-shot project pitch to a connected user
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { toUserId, text } = req.body;

    if (!toUserId || !text || !text.trim()) {
      return res.status(400).json({ message: 'toUserId and text are required' });
    }

    if (toUserId === req.user.id) {
      return res.status(400).json({ message: 'You cannot pitch yourself' });
    }

    const connection = await requireAcceptedConnection(req.user.id, toUserId);
    if (!connection) {
      return res.status(403).json({ message: 'You can only pitch to an accepted connection' });
    }

    const existingPitch = await Pitch.findOne({
      fromUser: req.user.id,
      toUser: toUserId,
      status: { $in: ['pending', 'accepted'] }
    });
    if (existingPitch) {
      return res.status(400).json({ message: 'You already sent a pitch to this user' });
    }

    const pitch = new Pitch({
      fromUser: req.user.id,
      toUser: toUserId,
      text: text.trim()
    });
    await pitch.save();

    const sender = await User.findById(req.user.id);

    const io = req.app.get('io');
    io.to(toUserId.toString()).emit('pitch_received', {
      pitchId: pitch._id,
      fromUserId: sender._id,
      fromName: sender.name,
      text: pitch.text
    });

    res.status(201).json({ pitch });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while sending pitch' });
  }
});

// GET /api/pitch/with/:userId — both sides of a pitch exchange with one user
router.get('/with/:userId', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;

    const [mine, theirs] = await Promise.all([
      Pitch.findOne({ fromUser: req.user.id, toUser: userId }),
      Pitch.findOne({ fromUser: userId, toUser: req.user.id }).populate('fromUser', 'name')
    ]);

    const bothAccepted =
      mine?.status === 'accepted' && theirs?.status === 'accepted';

    res.json({
      mine,
      theirs,
      bothAccepted
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching pitch' });
  }
});

// PUT /api/pitch/:pitchId/respond — accept or reject a pitch sent to you
router.put('/:pitchId/respond', authMiddleware, async (req, res) => {
  try {
    const { pitchId } = req.params;
    const { status } = req.body;

    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status must be accepted or rejected' });
    }

    const pitch = await Pitch.findById(pitchId);
    if (!pitch) {
      return res.status(404).json({ message: 'Pitch not found' });
    }

    if (pitch.toUser.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to respond to this pitch' });
    }

    pitch.status = status;
    await pitch.save();

    const responder = await User.findById(req.user.id);
    const io = req.app.get('io');

    io.to(pitch.fromUser.toString()).emit('pitch_responded', {
      pitchId: pitch._id,
      responderId: responder._id,
      responderName: responder.name,
      status
    });

    if (status === 'accepted') {
      const reciprocalPitch = await Pitch.findOne({
        fromUser: pitch.toUser,
        toUser: pitch.fromUser,
        status: 'accepted'
      });

      if (reciprocalPitch) {
        const matchedPayload = {
          userIds: [pitch.fromUser.toString(), pitch.toUser.toString()]
        };
        io.to(pitch.fromUser.toString()).emit('pitch_matched', matchedPayload);
        io.to(pitch.toUser.toString()).emit('pitch_matched', matchedPayload);
      }
    }

    res.json({ pitch });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while responding to pitch' });
  }
});

// POST /api/pitch/meet/share — relay a manually-created Google Meet link
router.post('/meet/share', authMiddleware, async (req, res) => {
  try {
    const { toUserId, meetLink } = req.body;

    if (!toUserId || !meetLink || !meetLink.trim()) {
      return res.status(400).json({ message: 'toUserId and meetLink are required' });
    }

    const sender = await User.findById(req.user.id);

    const io = req.app.get('io');
    io.to(toUserId.toString()).emit('meet_link_shared', {
      fromUserId: sender._id,
      fromName: sender.name,
      meetLink: meetLink.trim()
    });

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while sharing meet link' });
  }
});

module.exports = router;
