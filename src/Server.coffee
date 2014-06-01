chat = require('./Chat').Chat
sock = require('socket.io')()

connections = {}

dChat = new chat

sock.on 'connection', (socket) ->
    connections[socket.id] = socket
    socket.on 'act', (data) ->
        dChat.handle connections, sock, socket.id, data

sock.listen 8080
