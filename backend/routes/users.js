// backend/routes/users.js
const express = require('express');
const User = require('../models/User');
const Connection = require('../models/Connection');
const authMiddleware = require('../middleware/authMiddleware');
const { calculateMatch } = require('../utils/interestGraph');
const { isPreferenceCompatible } = require('../utils/preferenceMatch');

const router = express.Router();

function getDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// GET /api/users/nearby
router.get('/nearby', authMiddleware, async (req, res) => {
  try {
    const { latitude, longitude, maxDistance } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ message: 'latitude and longitude are required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = maxDistance ? parseInt(maxDistance, 10) : 5000;

    const currentUser = await User.findById(req.user.id);
    if (!currentUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    const nearbyUsers = await User.find({
      _id: { $ne: currentUser._id },
      location: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [lng, lat]
          },
          $maxDistance: radius
        }
      }
    });

    const myConnections = await Connection.find({
      $or: [{ senderId: currentUser._id }, { receiverId: currentUser._id }]
    }).sort({ createdAt: -1 });

    const statusByUserId = {};
    myConnections.forEach((connection) => {
      const otherId =
        connection.senderId.toString() === currentUser._id.toString()
          ? connection.receiverId.toString()
          : connection.senderId.toString();
      if (!statusByUserId[otherId]) {
        statusByUserId[otherId] = connection.status;
      }
    });

    const results = nearbyUsers.map((user) => {
      const [userLng, userLat] = user.location.coordinates;
      const distanceKm = getDistanceKm(lat, lng, userLat, userLng);
      const { matchPercent, relatedInterests } = calculateMatch(
        currentUser.interests,
        user.interests
      );

      return {
        id: user._id,
        name: user.name,
        age: user.age,
        interests: user.interests,
        preference: user.preference,
        preferenceMatch: isPreferenceCompatible(currentUser.preference, user.preference),
        avatarColor: user.avatarColor,
        bio: user.bio,
        distanceKm: Math.round(distanceKm * 10) / 10,
        matchPercent,
        relatedInterests,
        connectionStatus: statusByUserId[user._id.toString()] || 'none'
      };
    });

    results.sort((a, b) => b.matchPercent - a.matchPercent);

    res.json({ users: results });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching nearby users' });
  }
});

// PUT /api/users/location
router.put('/location', authMiddleware, async (req, res) => {
  try {
    const { latitude, longitude } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: 'latitude and longitude are required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.location = {
      type: 'Point',
      coordinates: [longitude, latitude]
    };
    user.lastLocationAt = new Date();
    await user.save();

    res.json({
      user: {
        id: user._id,
        location: user.location,
        lastLocationAt: user.lastLocationAt
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while updating location' });
  }
});

// POST /api/users/connect
router.post('/connect', authMiddleware, async (req, res) => {
  try {
    const { receiverId } = req.body;

    if (!receiverId) {
      return res.status(400).json({ message: 'receiverId is required' });
    }

    if (receiverId === req.user.id) {
      return res.status(400).json({ message: 'You cannot connect with yourself' });
    }

    const receiver = await User.findById(receiverId);
    if (!receiver) {
      return res.status(404).json({ message: 'Receiver not found' });
    }

    const existingConnection = await Connection.findOne({
      $or: [
        { senderId: req.user.id, receiverId },
        { senderId: receiverId, receiverId: req.user.id }
      ],
      status: { $in: ['pending', 'accepted'] }
    });

    if (existingConnection) {
      const message =
        existingConnection.status === 'accepted'
          ? 'You are already connected'
          : 'Connection request already sent';
      return res.status(400).json({ message });
    }

    const connection = new Connection({
      senderId: req.user.id,
      receiverId,
      status: 'pending'
    });

    await connection.save();

    const sender = await User.findById(req.user.id);

    const io = req.app.get('io');
    io.to(receiverId.toString()).emit('connection_request', {
      connectionId: connection._id,
      senderId: sender._id,
      senderName: sender.name,
      avatarColor: sender.avatarColor
    });

    res.status(201).json({ connection });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while sending connection request' });
  }
});

// PUT /api/users/connect/:connectionId/respond
router.put('/connect/:connectionId/respond', authMiddleware, async (req, res) => {
  try {
    const { connectionId } = req.params;
    const { status } = req.body;

    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status must be accepted or rejected' });
    }

    const connection = await Connection.findById(connectionId);
    if (!connection) {
      return res.status(404).json({ message: 'Connection not found' });
    }

    if (connection.receiverId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'Not authorized to respond to this connection' });
    }

    connection.status = status;
    await connection.save();

    if (status === 'accepted') {
      const receiver = await User.findById(req.user.id);
      const io = req.app.get('io');
      io.to(connection.senderId.toString()).emit('connection_accepted', {
        connectionId: connection._id,
        receiverId: receiver._id,
        receiverName: receiver.name
      });
    }

    res.json({ connection });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while responding to connection' });
  }
});

// GET /api/users/requests/incoming
router.get('/requests/incoming', authMiddleware, async (req, res) => {
  try {
    const pending = await Connection.find({
      receiverId: req.user.id,
      status: 'pending'
    })
      .populate('senderId', 'name avatarColor age interests bio')
      .sort({ createdAt: -1 });

    const requests = pending
      .filter((connection) => connection.senderId)
      .map((connection) => ({
        connectionId: connection._id,
        senderId: connection.senderId._id,
        senderName: connection.senderId.name,
        avatarColor: connection.senderId.avatarColor,
        age: connection.senderId.age,
        interests: connection.senderId.interests,
        bio: connection.senderId.bio,
        createdAt: connection.createdAt
      }));

    res.json({ requests });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching incoming requests' });
  }
});

// GET /api/users/connections/accepted
router.get('/connections/accepted', authMiddleware, async (req, res) => {
  try {
    const accepted = await Connection.find({
      $or: [{ senderId: req.user.id }, { receiverId: req.user.id }],
      status: 'accepted'
    })
      .populate('senderId', 'name avatarColor age bio interests')
      .populate('receiverId', 'name avatarColor age bio interests')
      .sort({ createdAt: -1 });

    const connections = accepted
      .map((connection) => {
        const isSender = connection.senderId._id.toString() === req.user.id;
        const other = isSender ? connection.receiverId : connection.senderId;
        if (!other) return null;
        return {
          id: other._id,
          name: other.name,
          avatarColor: other.avatarColor,
          age: other.age,
          bio: other.bio,
          interests: other.interests
        };
      })
      .filter(Boolean);

    res.json({ connections });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching accepted connections' });
  }
});

// GET /api/users/profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while fetching profile' });
  }
});

// PUT /api/users/profile
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { name, bio, interests, preference, latitude, longitude } = req.body;

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (name !== undefined) user.name = name;
    if (bio !== undefined) user.bio = bio;
    if (interests !== undefined) user.interests = interests;
    if (preference !== undefined) user.preference = preference;
    if (latitude !== undefined && longitude !== undefined) {
      user.location = {
        type: 'Point',
        coordinates: [longitude, latitude]
      };
    }

    await user.save();

    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        age: user.age,
        interests: user.interests,
        preference: user.preference,
        location: user.location,
        avatarColor: user.avatarColor,
        bio: user.bio
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error while updating profile' });
  }
});

module.exports = router;
