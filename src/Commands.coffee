exports.ChatCommands = class ChatCommands
    # Constructor
    constructor: (chat) ->
        @chat = chat
        
    ###

        Commands:
            login  - sockdata, username
            logout - sockdata
            say    - sockdata, message
            info   - sockdata
            adminAuth     - sockdata, password
            adminGetUsers - sockdata
            adminKick     - sockdata, userid
            adminClear    - sockdata
            adminGetID    - sockdata, username
            adminSetPerm  - sockdata, userid, permname, permdata

    ###
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Login command
    login: (sockdata, username) ->
        # Set up some variables
        id = sockdata.i
        # Check if user with same id is already online
        if @chat.users.getUserByID(id) isnt null
            # Emit success as if you are logged in successfully
            @chat.net.suc sockdata, 'loggedIn'
            return
        # Valid username is username with length of 1-30
        # Check if 'username' isnt null
        if !username? || typeof username isnt 'string'
            @chat.net.err sockdata, 'invalidRequest'
            return
        # Check if 'username' isnt longer than 30
        if username.length > 30 || username.length is 0
            @chat.net.err sockdata, 'wrongUsername'
            return
        # Check if user with same name is online already
        if @chat.users.getUserByName(username) isnt null
            @chat.net.err sockdata, 'nameTaken'
            return
        # Create new user
        @chat.users.createNewUser id, username
        # Tell everyone about it
        @chat.msg.post sockdata, 'event',
            event: 'user'
            user: 'in'
            data:
                name: username
            escape: yes
        , 'all'
        # Return success to client
        @chat.net.suc sockdata, 'loggedIn'
        # End
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Logout command
    logout: (sockdata) ->
        # Set up some variables
        id = sockdata.i
        # Check if user is online
        if @chat.users.getUserByID(id) is null
            @chat.net.err sockdata, 'noUser'
            return
        # Tell everyone about it
        @chat.msg.post sockdata, 'event',
            event: 'user'
            user: 'out'
            data:
                name: @chat.users.getUserByID(id).name
            escape: yes
        , 'all'
        # Delete the user
        @chat.users.removeUser id
        # Return success to client
        @chat.net.suc sockdata, 'loggedOut'
        # End
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # Say command
    say: (sockdata, message) ->
        # Set up some variables
        id = sockdata.i
        u  = @chat.users.getUserByID(id)
        # Check if user is online
        if u is null
            @chat.net.err sockdata, 'noUser'
            return
        # Check if user has permission 'msg.say'
        if u.getPermission('msg.say') is no
            @chat.net.err sockdata, 'noPermission'
            return
        # Check if message is valid
        # Valid message is message with length of 1-450 with symbols other than spaces
        # Check if message isnt null and is not made of spaces
        if !message? || typeof message isnt 'string' || message.match /^\s*$/
            @chat.net.err sockdata, 'invalidRequest'
            return
        # Check message length or permission 'msg.long'
        if (message.length > 450 || message.length is 0) && u.getPermission('msg.long') is no
            @chat.net.err sockdata, 'longMessage'
            return
        # Check if user is not flooding and does not have permission 'msg.fast'
        if Date.now() - u.lastMessage < 500 && u.getPermission('msg.fast') is no
            @chat.net.err sockdata, 'tooFast'
            return
        # Set user message cooldown
        u.lastMessage = Date.now()
        # Tell everyone about it
        @chat.msg.post sockdata, 'msg',
            data:
                name: u.name
                text: message
        , 'all'
            # If user has permission 'msg.html' then we must not to remove tags
            escape: if u.getPermission('msg.html') then no else yes
        # Return success to client
        @chat.net.suc sockdata, 'messageSent'
        # End
        return
        