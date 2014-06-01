sock = require('socket.io')()
clients = {}

chat = require './Chat.js'
dacx = new chat

sock.on 'connection', (socket) ->
    console.log "[SOCK] A connection from #{socket.handshake.address.address}:#{socket.id}"
    clients[socket.id] = socket
    socket.on 'act', (data) ->
        dacx.handle sock, clients[socket.id], socket.id, data
    socket.on 'disconnect', (s) ->
        dacx.handle sock, clients[socket.id], socket.id, {act: 'logout'}

sock.listen process.env.PORT ? 8080