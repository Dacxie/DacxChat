exports.ChatNetwork = class ChatNetwork
    # Constructor
    constructor: (chat) ->
        @chat = chat
        
    ###

        Commands:
            suc: sockdata, message
            err: sockdata, message
            evt: sockdata, message, to

    ###
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Success command
    suc: (sockdata, message) ->
        sockdata.c.emit 'cSuccess',
            data: message
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Error command
    err: (sockdata, message) ->
        sockdata.c.emit 'cError',
            data: message
            
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Event command
    evt: (sockdata, message, to) ->
        switch to
            when 'all'
                sockdata.s.sockets.emit 'cEvent', message
            when 'cli'
                sockdata.c.emit 'cEvent', message
            else
                sockdata.a[to].emit 'cEvent', message