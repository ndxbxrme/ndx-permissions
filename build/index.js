(function() {
  'use strict';
  module.exports = function() {
    var authenticate, permissions;
    permissions = {};
    authenticate = null;
    return {
      check: function(op, table, user) {
        var permissionOp, permissionTable;
        if (permissionTable = permissions[table]) {
          if (permissionOp = permissionTable[op] || permissionTable['all']) {
            if (authenticate && authenticate(permissionOp)) {
              true;
            } else {
              throw 'Not authorized';
            }
          }
        }
        return true;
      },
      getTransformer: function(op, table, user) {
        var permissionOp, permissionTable;
        if (permissionTable = permissions[table]) {
          if (permissionOp = permissionTable[op] || permissionTable['all']) {
            return permissionOp.transformer;
          }
        }
      },
      setPermissions: function(_permissions) {
        permissions = _permissions;
      },
      setAuthenticate: function(authenticateFn) {
        authenticate = authenticateFn;
      }
    };
  };

}).call(this);

//# sourceMappingURL=index.js.map
