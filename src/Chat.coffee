ChatNetwork  = require('./Network').ChatNetwork
ChatMessages = require('./Messages').ChatMessages
ChatUsers    = require('./Users').ChatUsers
ChatCommands = require('./Commands').ChatCommands

exports.Chat = class Chat
    # Constructor
    constructor: ->
        @net   = new ChatNetwork this
        @msg   = new ChatMessages this
        @users = new ChatUsers this
        @cmd   = new ChatCommands this
        
    ###

        Commands:
            handle: (sockdata, data)

    ###
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Handle command
    handle: (connections, sock, id, data) ->
        # Construct 'sockdata'
        sockdata =
            c: connections[id]
            a: connections
            s: sock
            i: id
        # Check if data.act exists and its type is string
        if !data.act? || typeof data.act isnt 'string'
            @net.err sockdata, 'noAction'
            return
        switch data.act
            # Route action
            when 'login'
                @cmd.login sockdata, data.name
            when 'logout'
                @cmd.logout sockdata
            when 'say'
                @cmd.say sockdata, data.text
            else
                @net.err sockdata, 'noAction'