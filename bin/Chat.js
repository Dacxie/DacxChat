(function() {
  var g;
  g = this;
  this.User = (function() {
    function User(name, sid, ip) {
      this.name = name;
      this.id = sid;
      this.last = 0;
      this.ip = ip;
      this.perm = {
        say: true
      };
    }
    return User;
  })();
  this.Chat = (function() {
    var escape;
    function Chat() {
      this.users = {};
      this.messages = [];
    }
    escape = function(string) {
      return string.replace(/&/, '&amp;').replace(/>/, '&gt').replace(/</, '&lt');
    };
    Chat.prototype.netErr = function(sockdata, data) {
      return sockdata.c.emit('chatError', {
        data: data
      });
    };
    Chat.prototype.netSuc = function(sockdata, data) {
      return sockdata.c.emit('chatSuccess', {
        data: data
      });
    };
    Chat.prototype.netEvt = function(sockdata, data, to) {
      switch (to) {
        case 'all':
          return sockdata.s.sockets.emit('chatEvent', {
            data: data
          });
        case 'cli':
          return sockdata.c.emit('chatEvent', {
            data: data
          });
        default:
          return sockdata.s.socket(to).emit('chatEvent', {
            data: data
          });
      }
    };
    Chat.prototype.netDat = function(sockdata, data, to) {
      switch (to) {
        case 'all':
          return sockdata.s.sockets.emit('chatData', {
            data: data
          });
        case 'cli':
          return sockdata.c.emit('chatData', {
            data: data
          });
        default:
          return sockdata.s.socket(to).emit('chatData', {
            data: data
          });
      }
    };
    Chat.prototype.netMsg = function(sockdata, data) {
      if (data.text != null) {
        if (decodeURIComponent(data.text).indexOf('<script>') >= 0) {
          data.noArc = true;
        }
      }
      this.messages.push(data);
      return this.netEvt(sockdata, data, 'all');
    };
    Chat.prototype.usrGetData = function(id) {
      if (this.users[id] != null) {
        return "" + id + ":" + this.users[id].name;
      }
      return "" + id;
    };
    Chat.prototype.usrSetPerm = function(id, perm, data, sockdata) {
      if (this.users[id] != null) {
        this.users[id].perm[perm] = data;
        console.log("[USRSETPERM] " + (this.usrGetData(id)) + " - " + perm + " is now " + data);
        if (sockdata != null) {
          this.netMsg(sockdata, {
            event: 'user',
            type: 'permission',
            name: encodeURIComponent(this.users[id].name),
            perm: perm,
            data: data
          });
        }
      }
    };
    Chat.prototype.usrGetPerm = function(id, perm) {
      if (this.users[id] != null) {
        if (this.users[id].perm.admin === true) {
          return true;
        }
        if (this.users[id].perm[perm] === true) {
          return true;
        }
      }
      return false;
    };
    Chat.prototype.handle = function(sock, client, id, data) {
      var sockdata;
      sockdata = {
        s: sock,
        c: client,
        i: id
      };
      if (!(data.act != null)) {
        this.netErr(sockdata, 'noAction');
        return;
      }
      switch (data.act) {
        case 'getOld':
          this.getOld(sockdata);
          break;
        case 'login':
          this.login(sockdata, data.name);
          break;
        case 'logout':
          this.logout(sockdata);
          break;
        case 'msg':
          this.msg(sockdata, data.text);
          break;
        case 'adminLogin':
          this.adminLogin(sockdata, data.password);
          break;
        case 'adminSetPerm':
          this.adminSetPerm(sockdata, data.id, data.perm, data.data);
          break;
        case 'userGetInfo':
          this.userGetInfo(sockdata);
          break;
        case 'adminGetInfo':
          this.adminGetInfo(sockdata);
          break;
        case 'adminClearChat':
          this.adminClearChat(sockdata);
          break;
        default:
          this.netErr(sockdata, 'unknownAction');
      }
    };
    Chat.prototype.getOld = function(sockdata) {
      var msg, _i, _len, _ref;
      console.log("[GETOLD] " + (this.usrGetData(sockdata.i)) + " - Requested old messages");
      _ref = this.messages;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        msg = _ref[_i];
        if (msg.noArc === true) {} else {
          this.netEvt(sockdata, msg, 'cli');
        }
      }
    };
    Chat.prototype.login = function(sockdata, name) {
      var data, user, _ref;
      if (!(name != null)) {
        this.netErr(sockdata, 'invalidName');
        console.log("[LOGIN] " + (this.usrGetData(sockdata.i)) + " - Invalid name: null");
        return;
      }
      if (this.users[sockdata.i] != null) {
        this.netSuc(sockdata, 'loggedIn');
        console.log("[LOGIN] " + (this.usrGetData(sockdata.i)) + " - Relogin as " + name);
        return;
      }
      _ref = this.users;
      for (user in _ref) {
        data = _ref[user];
        if (data.name === name) {
          this.netErr(sockdata, 'nameTaken');
          console.log("[LOGIN] " + (this.usrGetData(sockdata.i)) + " - Name taken");
          return;
        }
      }
      if (name.length > 30 || name.length <= 0) {
        this.netErr(sockdata, 'invalidName');
        console.log("[LOGIN] " + (this.usrGetData(sockdata.i)) + " - Username length is invalid");
        return;
      }
      this.users[sockdata.i] = new g.User(name, sockdata.i, sockdata.c.handshake.address.address);
      this.netMsg(sockdata, {
        event: 'user',
        type: 'login',
        name: encodeURIComponent(name),
        esc: 1
      });
      this.netSuc(sockdata, 'loggedIn');
      console.log("[LOGIN] " + (this.usrGetData(sockdata.i)) + " - Logged in to chat");
    };
    Chat.prototype.msg = function(sockdata, msg) {
      if (!(this.users[sockdata.i] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[MSG] " + (this.usrGetData(sockdata.i)) + " - Does not exist");
        return;
      }
      if (this.usrGetPerm(sockdata.i, 'say') === false) {
        this.netErr(sockdata, 'noPermission');
        console.log("[MSG] " + (this.usrGetData(sockdata.i)) + " - No permission 'say'");
        return;
      }
      if (!(msg != null) || msg.match(/^\s*$/)) {
        this.netErr(sockdata, 'invalidMsg');
        console.log("[MSG] " + (this.usrGetData(sockdata.i)) + " - Sent empty message");
        return;
      }
      if (Date.now() - this.users[sockdata.i].last < 500 && !this.usrGetPerm(sockdata.i, 'nowait')) {
        this.netErr(sockdata, 'flooding');
        console.log("[MSG] " + (this.usrGetData(sockdata.i)) + " - Flooding");
        return;
      }
      if (msg.length > 600 && !this.usrGetData(sockdata.i, 'longmsg')) {
        this.netErr(sockdata, 'invalidMsg');
        console.log("[MSG] " + (this.usrGetData(sockdata.i)) + " - Sent very long message (" + msg.length + ")");
        return;
      }
      this.netMsg(sockdata, {
        event: 'msg',
        from: encodeURIComponent(this.users[sockdata.i].name),
        text: encodeURIComponent(msg),
        esc: this.usrGetPerm(sockdata.i, 'noesc') ? 0 : 1
      });
      this.netSuc(sockdata, 'accepted');
      console.log("[MSG] " + (this.usrGetData(sockdata.i)) + ": " + msg);
      this.users[sockdata.i].last = Date.now();
    };
    Chat.prototype.logout = function(sockdata) {
      if (this.users[sockdata.i] != null) {
        console.log("[LOGOUT] " + (this.usrGetData(sockdata.i)) + " - Logged out");
        this.netMsg(sockdata, {
          event: 'user',
          type: 'logout',
          name: encodeURIComponent(this.users[sockdata.i].name),
          esc: 1
        });
        delete this.users[sockdata.i];
        this.netSuc(sockdata, 'loggedOut');
      } else {
        this.netErr(sockdata, 'invalidId');
        console.log("[LOGOUT] " + (this.usrGetData(sockdata.i)) + " - Invalid user ID");
      }
    };
    Chat.prototype.adminSetPerm = function(sockdata, id, perm, data) {
      if (!(perm != null) || !(data != null)) {
        this.netErr(sockdata, 'missingFields');
        console.log("[ADMINSETPERM] " + (this.usrGetData(sockdata.i)) + " - Invalid request");
        return;
      }
      if (!(this.users[sockdata.i] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[ADMINSETPERM] " + (this.usrGetData(sockdata.i)) + " - Invalid user ID");
        return;
      }
      if (!(this.users[id] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[ADMINSETPERM] " + (this.usrGetData(id)) + " - Invalid target ID");
        return;
      }
      if (this.usrGetPerm(sockdata.i, 'setperm') === false) {
        this.netErr(sockdata, 'noPermission');
        console.log("[ADMINSETPERM] " + (this.usrGetData(sockdata.i)) + " - No permission setperm");
        return;
      }
      this.usrSetPerm(id, perm, data, sockdata);
      this.netSuc(sockdata, 'permSet');
    };
    Chat.prototype.adminLogin = function(sockdata, password) {
      if (!(this.users[sockdata.i] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[ADMINLOGIN] " + (this.usrGetData(sockdata.i)) + " - Invalid user ID");
        return;
      }
      if (this.usrGetPerm(sockdata.i, 'admin')) {
        this.netSuc(sockdata, 'loggedAdmin');
        console.log("[ADMINLOGIN] " + (this.usrGetData(sockdata.i)) + " - Relogin");
        return;
      }
      if (password !== 'PawlQowneeckDacxie') {
        this.netErr(sockdata, 'wrongPass');
        console.log("[ADMINLOGIN] " + (this.usrGetData(sockdata.i)) + " - Wrong password: " + password);
        return;
      }
      this.usrSetPerm(sockdata.i, 'admin', true, sockdata);
      this.netSuc(sockdata, 'loggedAdmin');
      console.log("[ADMINLOGIN] " + (this.usrGetData(sockdata.i)) + " - Logged in");
    };
    Chat.prototype.adminGetInfo = function(sockdata) {
      if (!(this.users[sockdata.i] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[ADMINGETINFO] " + (this.usrGetData(sockdata.i)) + " - Invalid user ID");
        return;
      }
      if (this.usrGetPerm(sockdata.i, 'getinfo') === false) {
        console.log(this.usrGetPerm(sockdata.i, 'admin'));
        this.netErr(sockdata, 'noPermission');
        console.log("[ADMINGETINFO] " + (this.usrGetData(sockdata.i)) + " - No permission getinfo");
        return;
      }
      this.netDat(sockdata, {
        type: 'adminUserList',
        data: this.users
      }, 'cli');
      return console.log("[ADMINGETINFO] " + (this.usrGetData(sockdata.i)) + " - Got admin user data");
    };
    Chat.prototype.adminClearChat = function(sockdata) {
      if (!(this.users[sockdata.i] != null)) {
        this.netErr(sockdata, 'invalidId');
        console.log("[ADMINCLEARCHAT] " + (this.usrGetData(sockdata.i)) + " - Invalid user ID");
        return;
      }
      if (this.usrGetPerm(sockdata.i, 'clear') === false) {
        console.log(this.usrGetPerm(sockdata.i, 'admin'));
        this.netErr(sockdata, 'noPermission');
        console.log("[ADMINCLEARCHAT] " + (this.usrGetData(sockdata.i)) + " - No permission clear");
        return;
      }
      this.netEvt(sockdata, {
        event: 'chatCleared'
      }, 'all');
      return this.messages = [];
    };
    Chat.prototype.userGetInfo = function(sockdata) {
      var info;
      info = {
        count: Object.keys(this.users).length
      };
      return this.netDat(sockdata, {
        type: 'userInfo',
        data: info
      }, 'cli');
    };
    return Chat;
  })();
  module.exports = this.Chat;
}).call(this);
