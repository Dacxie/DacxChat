(function() {
  var chat, clients, dacx, sock, _ref;
  sock = require('socket.io')();
  clients = {};
  chat = require('./Chat.js');
  dacx = new chat;
  sock.on('connection', function(socket) {
    console.log("[SOCK] A connection from " + socket.handshake.address.address + ":" + socket.id);
    clients[socket.id] = socket;
    socket.on('act', function(data) {
      return dacx.handle(sock, clients[socket.id], socket.id, data);
    });
    return socket.on('disconnect', function(s) {
      return dacx.handle(sock, clients[socket.id], socket.id, {
        act: 'logout'
      });
    });
  });
  sock.listen((_ref = process.env.PORT) != null ? _ref : 8080);
}).call(this);
