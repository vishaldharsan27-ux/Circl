// backend/server.js
require('dotenv').config();

const express = require('express');
const http = require('http');
const path = require('path');
const cors = require('cors');
const mongoose = require('mongoose');
const { Server } = require('socket.io');

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const pitchRoutes = require('./routes/pitch');
const projectsRoutes = require('./routes/projects');
const socketHandler = require('./socket/socketHandler');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT']
  }
});

app.set('io', io);

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/pitch', pitchRoutes);
app.use('/api/projects', projectsRoutes);

const webBuildPath = path.join(__dirname, '..', 'build', 'web');
app.use(express.static(webBuildPath));
app.get(/^(?!\/api).*/, (req, res) => {
  res.sendFile(path.join(webBuildPath, 'index.html'));
});

socketHandler(io);

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI;

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log('Connected to MongoDB Atlas');
    server.listen(PORT, () => {
      console.log(`Circl backend server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });
