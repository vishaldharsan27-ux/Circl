// backend/socket/socketHandler.js
module.exports = function socketHandler(io) {
  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    socket.on('join', (userId) => {
      if (userId) {
        socket.join(userId.toString());
        console.log(`User ${userId} joined their room`);
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
};
