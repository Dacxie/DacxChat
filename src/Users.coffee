g = this

exports.ChatUser = class ChatUser
    constructor: (id, name) ->
        @id   = id
        @name = name
        @perm =
            'msg.say': yes
    getPermission: (permname) ->
        if @perm.admin is yes
            return yes
        if @perm[permname] is yes
            return yes
        return no
        
exports.ChatUsers = class ChatUsers
    # Constructor
    constructor: (chat) ->
        @chat = chat
        @data = {}
        
    ###

        Commands:
            getUserByID:   (id)
            getUserByName: (name)
            createNewUser: (id, name)
            removeUser:    (id)

    ###
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # GetUserByID command
    getUserByID: (id) ->
        # Return null if there is no user with that id
        if !@data[id]?
            return null
        else
            return @data[id]
        
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # GetUserByName command
    getUserByName: (name) ->
        # Iterate over 'data' array
        for id, user of @data
            if user.name is name
                return user
        return null
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # CreateNewUser command
    createNewUser: (id, name) ->
        @data[id] = new g.ChatUser id, name
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    # RemoveUser command
    removeUser: (id) ->
        if @getUserByID(id) is null
            return
        else
            delete @data[id]
            