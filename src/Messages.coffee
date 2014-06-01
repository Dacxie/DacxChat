exports.ChatMessages = class ChatMessages
    # Constructor
    constructor: (chat) ->
        @chat = chat
        
    ###

        Commands:
            post: (sockdata, message, to)
    
    ###
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Post command
    post: (sockdata, type, message, to) ->
        # Check if message has 'data' field
        if message.data? && typeof message.data is 'object'
            # URLEncode all of data in 'data' to prevent encoding errors while transfering
            for key, data of message.data
                message.data[key] = encodeURIComponent data
        # Post message through 'net.evt'
        @chat.net.evt sockdata, 
            type: type
            data: message
        , to