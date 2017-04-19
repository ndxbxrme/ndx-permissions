(function() {
  'use strict';
  require('ndx-server').config({
    database: 'db',
    tables: ['tb1']
  }).use(require('../index')).use(function(ndx) {
    return ndx.database.on('ready', function() {
      return ndx.database.insert('tb1', {
        mything: 'thing'
      });
    });
  }).use(function(ndx) {
    return ndx.user = {
      email: 'boop@boop.com',
      roles: {
        ADM: true,
        "a1": ['yes', 'view'],
        "a2": ['no', 'view'],
        "a3": ['yes', 'view']
      },
      hasRole: function(role) {
        var allgood, getKey, i, key, keys, len, root;
        getKey = function(root, key) {
          return root[key];
        };
        keys = role.split(/\./g);
        allgood = false;
        if (this.roles) {
          root = this.roles;
          for (i = 0, len = keys.length; i < len; i++) {
            key = keys[i];
            root = getKey(root, key);
            if (root) {
              allgood = true;
            } else {
              allgood = false;
              break;
            }
          }
        }
        return allgood;
      }
    };
  }).use(function(ndx) {
    return ndx.database.permissions.set({
      tb1: {
        select: ['sup', 'ADM', 'sap']
      }
    });
  }).controller(function(ndx) {
    return ndx.app.get('/', function(req, res, next) {
      return ndx.database.select('tb1', null, function(things, total) {
        return res.json(things);
      });
    });
  }).start();

}).call(this);

//# sourceMappingURL=test.js.map
