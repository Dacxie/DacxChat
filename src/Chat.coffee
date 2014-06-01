g = this

class @User
    constructor: (name, sid) ->
        @name = name
        @id   = sid
        @last = 0
        @perm = 
            say: yes
        
class @Chat
    constructor: () ->
        @users    = {}
        @messages = []
        
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    escape = (string) ->
        string.replace(/&/, '&amp;').replace(/>/, '&gt').replace(/</, '&lt');
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    netErr: (sockdata, data) ->
        sockdata.c.emit 'chatError',
            data: data

    # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    netSuc: (sockdata, data) ->
        sockdata.c.emit 'chatSuccess',
            data: data

    # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    netEvt: (sockdata, data, to) ->
        switch to
            when 'all'
                sockdata.s.sockets.emit 'chatEvent',
                    data: data
            when 'cli'
                sockdata.c.emit 'chatEvent',
                    data: data
            else
                sockdata.s.socket(to).emit 'chatEvent',
                    data: data

    # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    netDat: (sockdata, data, to) ->
        switch to
            when 'all'
                sockdata.s.sockets.emit 'chatData',
                    data: data
            when 'cli'
                sockdata.c.emit 'chatData',
                    data: data
            else
                sockdata.s.socket(to).emit 'chatData',
                    data: data

    # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    netMsg: (sockdata, data) ->
        if data.text?
            if decodeURIComponent(data.text).indexOf('<script>') >= 0
                data.noArc = true
        @messages.push data
        @netEvt sockdata, data, 'all'

    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            
    usrGetData: (id) ->
        if @users[id]?
            return "#{id}:#{@users[id].name}"
        return "#{id}"
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    usrSetPerm: (id, perm, data, sockdata) ->
        if @users[id]?
            @users[id].perm[perm] = data 
            console.log "[USRSETPERM] #{@usrGetData id} - #{perm} is now #{data}"
            if sockdata?
                @netMsg sockdata,
                    event: 'user'
                    type:  'permission'
                    name:  encodeURIComponent @users[id].name
                    perm:  perm
                    data:  data
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    usrGetPerm: (id, perm) ->
        if @users[id]?
            if @users[id].perm.admin is yes
                return yes
            if @users[id].perm[perm] is yes
                return yes
        return no
            
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    handle: (sock, client, id, data) ->
        # Construct SOCKDATA
        sockdata = 
            s: sock
            c: client
            i: id
        # Check if request is valid
        if !data.act?
            @netErr sockdata, 'noAction'
            return
        # Perform action
        switch data.act
            when 'getOld'
                @getOld sockdata
            when 'login'
                @login sockdata, data.name
            when 'logout'
                @logout sockdata
            when 'msg'
                @msg sockdata, data.text
            when 'adminLogin'
                @adminLogin sockdata, data.password
            when 'adminSetPerm'
                @adminSetPerm sockdata, data.id, data.perm, data.data
            when 'userGetInfo'
                @userGetInfo sockdata
            when 'adminGetInfo'
                @adminGetInfo sockdata
            when 'adminClearChat'
                @adminClearChat sockdata
            else
                @netErr sockdata, 'unknownAction'
                
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    getOld: (sockdata) ->
        # Notify console
        console.log "[GETOLD] #{@usrGetData sockdata.i} - Requested old messages"
        # Return old messages
        for msg in @messages
            if msg.noArc is yes
            else
                @netEvt sockdata, msg, 'cli'
            
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        
    login: (sockdata, name) ->
        # Check if name is valid
        if !name?
            @netErr sockdata, 'invalidName'
            console.log "[LOGIN] #{@usrGetData sockdata.i} - Invalid name: null"
            return
        # If user is already online
        if @users[sockdata.i]?
            @netSuc sockdata, 'loggedIn'
            console.log "[LOGIN] #{@usrGetData sockdata.i} - Relogin as #{name}"
            return
        # Check if user with same name is online
        for user, data of @users
            if data.name == name
                @netErr sockdata, 'nameTaken'
                console.log "[LOGIN] #{@usrGetData sockdata.i} - Name taken"
                return
        # Check name length
        if name.length > 30 || name.length <= 0
            @netErr sockdata, 'invalidName'
            console.log "[LOGIN] #{@usrGetData sockdata.i} - Username length is invalid"
            return
        # Create new user
        @users[sockdata.i] = new g.User name, sockdata.i
        # Tell everyone about it
        @netMsg sockdata, 
            event: 'user'
            type:  'login'
            name:  encodeURIComponent name
            esc:   1
        # Tell client about it
        @netSuc sockdata, 'loggedIn'
        # Tell console about it
        console.log "[LOGIN] #{@usrGetData sockdata.i} - Logged in to chat"
        
        return
        
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
        
    msg: (sockdata, msg) ->
        # Check if user exists
        if !@users[sockdata.i]?
            @netErr sockdata, 'invalidId'
            console.log "[MSG] #{@usrGetData sockdata.i} - Does not exist"
            return
        # Check if user has permission to talk
        if @usrGetPerm(sockdata.i, 'say') is no
            @netErr sockdata, 'noPermission'
            console.log "[MSG] #{@usrGetData sockdata.i} - No permission 'say'"
            return
        # Check if message is empty
        if !msg? || msg.match /^\s*$/
            @netErr sockdata, 'invalidMsg'
            console.log "[MSG] #{@usrGetData sockdata.i} - Sent empty message"
            return
        # Check if user is flooding
        if Date.now() - @users[sockdata.i].last < 500 && !@usrGetPerm sockdata.i, 'nowait'
            @netErr sockdata, 'flooding'
            console.log "[MSG] #{@usrGetData sockdata.i} - Flooding"
            return
        # Check if message is too long
        if msg.length > 600 && !@usrGetData sockdata.i, 'longmsg'
            @netErr sockdata, 'invalidMsg'
            console.log "[MSG] #{@usrGetData sockdata.i} - Sent very long message (#{msg.length})"
            return
        # Tell everyone about it
        @netMsg sockdata,
            event: 'msg'
            from:  encodeURIComponent @users[sockdata.i].name
            text:  encodeURIComponent msg
            esc:   if @usrGetPerm sockdata.i, 'noesc' then 0 else 1
        # Tell client about it
        @netSuc sockdata, 'accepted'
        # Tell console about it
        console.log "[MSG] #{@usrGetData sockdata.i}: #{msg}"
        # Set user's msg cooldown
        @users[sockdata.i].last = Date.now()
        
        return
                
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            
    logout: (sockdata) ->
        # Check if user exists
        if @users[sockdata.i]?
            # Tell console about it
            console.log "[LOGOUT] #{@usrGetData sockdata.i} - Logged out"
            # Tell everyone about it
            @netMsg sockdata,
                event: 'user'
                type:  'logout'
                name:  encodeURIComponent @users[sockdata.i].name
                esc:   1
            # Actually delete the user
            delete @users[sockdata.i]
            # Tell client about it
            @netSuc sockdata, 'loggedOut'
        else
            @netErr sockdata, 'invalidId'
            console.log "[LOGOUT] #{@usrGetData sockdata.i} - Invalid user ID"
            
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #    
    
    adminSetPerm: (sockdata, id, perm, data) ->
        # Check if perm and data are correct
        if !perm? || !data?
            @netErr sockdata, 'missingFields'
            console.log "[ADMINSETPERM] #{@usrGetData sockdata.i} - Invalid request"
            return
        # Check if user exists
        if !@users[sockdata.i]?
            @netErr sockdata, 'invalidId'
            console.log "[ADMINSETPERM] #{@usrGetData sockdata.i} - Invalid user ID"
            return
        # Check if target exists
        if !@users[id]?
            @netErr sockdata, 'invalidId'
            console.log "[ADMINSETPERM] #{@usrGetData id} - Invalid target ID"
            return
        # Check if user has ADMIN permission
        if @usrGetPerm(sockdata.i, 'setperm') is no
            @netErr sockdata, 'noPermission'
            console.log "[ADMINSETPERM] #{@usrGetData sockdata.i} - No permission setperm"
            return
        # Set permission
        @usrSetPerm id, perm, data, sockdata
        # Tell client about it
        @netSuc sockdata, 'permSet'
        
        return
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #    
    
    adminLogin: (sockdata, password) ->
        # Check if user exists
        if !@users[sockdata.i]?
            @netErr sockdata, 'invalidId'
            console.log "[ADMINLOGIN] #{@usrGetData sockdata.i} - Invalid user ID"
            return
        # Check if user is not admin
        if @usrGetPerm sockdata.i, 'admin'
            @netSuc sockdata, 'loggedAdmin'
            console.log "[ADMINLOGIN] #{@usrGetData sockdata.i} - Relogin"
            return
        # Check if password is correct
        if password isnt 'PawlQowneeckDacxie'
            @netErr sockdata, 'wrongPass'
            console.log "[ADMINLOGIN] #{@usrGetData sockdata.i} - Wrong password: #{password}"
            return
        # Actually give admin rights
        @usrSetPerm sockdata.i, 'admin', yes, sockdata
        # Tell client about it
        @netSuc sockdata, 'loggedAdmin'
        # Tell console about it
        console.log "[ADMINLOGIN] #{@usrGetData sockdata.i} - Logged in"
        
        return
        
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
    
    adminGetInfo: (sockdata) ->
        # Check if user exists
        if !@users[sockdata.i]?
            @netErr sockdata, 'invalidId'
            console.log "[ADMINGETINFO] #{@usrGetData sockdata.i} - Invalid user ID"
            return
        # Check if user has permission
        if @usrGetPerm(sockdata.i, 'getinfo') is no
            console.log @usrGetPerm sockdata.i, 'admin'
            @netErr sockdata, 'noPermission'
            console.log "[ADMINGETINFO] #{@usrGetData sockdata.i} - No permission getinfo"
            return
        # Return info
        @netDat sockdata, 
            type: 'adminUserList'
            data: @users
        , 'cli'
        # Tell console about it
        console.log "[ADMINGETINFO] #{@usrGetData sockdata.i} - Got admin user data"
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #  
    
    adminClearChat: (sockdata) ->
        # Check if user exists
        if !@users[sockdata.i]?
            @netErr sockdata, 'invalidId'
            console.log "[ADMINCLEARCHAT] #{@usrGetData sockdata.i} - Invalid user ID"
            return
        # Check if user has permission
        if @usrGetPerm(sockdata.i, 'clear') is no
            console.log @usrGetPerm sockdata.i, 'admin'
            @netErr sockdata, 'noPermission'
            console.log "[ADMINCLEARCHAT] #{@usrGetData sockdata.i} - No permission clear"
            return
        # Clear che chat
        @netEvt sockdata,
            event: 'chatCleared'
        , 'all'
        # Clear the history
        @messages = []
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #  
    
    userGetInfo: (sockdata) ->
        # Construct and return info
        info =
            count: Object.keys(@users).length
        @netDat sockdata,
            type: 'userInfo'
            data: info
        , 'cli'
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # #  
  
module.exports = @Chat