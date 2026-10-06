// backend/routes/auth.js
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

const AVATAR_COLORS = [
  '#00E676',
  '#FF5252',
  '#448AFF',
  '#FFD740',
  '#E040FB',
  '#40C4FF',
  '#FF6E40',
  '#69F0AE'
];

function generateToken(user) {
  return jwt.sign({ id: user._id.toString(), email: user.email }, process.env.JWT_SECRET, {
    expiresIn: '30d'
  });
}

function sanitizeUser(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    age: user.age,
    interests: user.interests,
    preference: user.preference,
    location: user.location,
    avatarColor: user.avatarColor,
    bio: user.bio,
    createdAt: user.createdAt
  };
}

router.post('/register', async (req, res) => {
  try {
    const { name, email, password, age, interests, preference, latitude, longitude } = req.body;

    if (!name || !email || !password || !age) {
      return res.status(400).json({ message: 'Name, email, password and age are required' });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ message: 'Email is already registered' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const avatarColor = AVATAR_COLORS[Math.floor(Math.random() * AVATAR_COLORS.length)];

    const user = new User({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      age,
      interests: interests || [],
      preference: preference || null,
      location: {
        type: 'Point',
        coordinates: [longitude || 0, latitude || 0]
      },
      lastLocationAt: latitude && longitude ? new Date() : null,
      avatarColor
    });

    await user.save();

    const token = generateToken(user);

    res.status(201).json({
      token,
      user: sanitizeUser(user)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const token = generateToken(user);

    res.json({
      token,
      user: sanitizeUser(user)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error during login' });
  }
});

module.exports = router;
