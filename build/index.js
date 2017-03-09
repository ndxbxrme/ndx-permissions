(function() {
  'use strict';
  module.exports = function(ndx) {
    var check, getTransformer, permissions;
    permissions = {};
    check = function(op, table, obj) {
      var permissionOp, permissionTable;
      if (permissionTable = permissions[table]) {
        if (permissionOp = permissionTable[op] || permissionTable['all']) {
          if (authenticate && authenticate(permissionOp, obj)) {
            true;
          } else {
            throw 'Not authorized';
          }
        }
      }
      return true;
    };
    getTransformer = function(op, table, obj) {
      var permissionOp, permissionTable;
      if (permissionTable = permissions[table]) {
        if (permissionOp = permissionTable[op] || permissionTable['all']) {
          return permissionOp.transformer;
        }
      }
    };
    ndx.database.on('preSelect', function(args) {
      if (!args.isServer) {
        return check('select', args.table);
      }
    });
    ndx.database.on('select', function(args) {
      var i, item, len, ref, results, transformer;
      if (!args.isServer) {
        if (transformer = getTransformer('select', args.table)) {
          ref = args.objs;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            results.push(item = objtrans(item, transformer));
          }
          return results;
        }
      }
    });
    ndx.database.on('preUpdate', function(args) {
      var transformer;
      if (!args.isServer) {
        check('update', args.table, args.obj);
        if (transformer = getTransformer('update', args.table)) {
          return args.obj = objtrans(args.obj, transformer);
        }
      }
    });
    ndx.database.on('preInsert', function(args) {
      var transformer;
      if (!args.isServer) {
        check('insert', args.table, args.obj);
        if (transformer = getTransformer('insert', args.table)) {
          return args.obj = objtrans(args.obj, transformer);
        }
      }
    });
    ndx.database.on('preDelete', function(args) {
      if (!args.isServer) {
        return check('delete', args.table);
      }
    });
    return {
      setPermissions: function(_permissions) {
        permissions = _permissions;
      },
      setAuthenticate: function(authenticateFn) {
        var authenticate;
        authenticate = authenticateFn;
      }
    };
  };

}).call(this);

//# sourceMappingURL=index.js.map
