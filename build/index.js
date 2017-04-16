(function() {
  'use strict';
  module.exports = function(ndx) {
    var check, getTransformer, permissions;
    permissions = {};
    check = function(op, table, obj) {
      var permissionOp, permissionTable;
      if (permissionTable = permissions[table]) {
        if (permissionOp = permissionTable[op] || permissionTable['all']) {
          if (ndx.authenticate && ndx.authenticate(permissionOp, obj)) {
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
    ndx.database.on('preSelect', function(args, cb) {
      if (!args.isServer) {
        check('select', args.table);
      }
      return cb();
    });
    ndx.database.on('select', function(args, cb) {
      var i, item, len, ref, transformer;
      if (!args.isServer) {
        if (transformer = getTransformer('select', args.table)) {
          ref = args.objs;
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            item = objtrans(item, transformer);
          }
        }
      }
      return cb();
    });
    ndx.database.on('preUpdate', function(args, cb) {
      var transformer;
      if (!args.isServer) {
        check('update', args.table, args.obj);
        if (transformer = getTransformer('update', args.table)) {
          args.obj = objtrans(args.obj, transformer);
        }
      }
      return cb();
    });
    ndx.database.on('preInsert', function(args, cb) {
      var transformer;
      if (!args.isServer) {
        check('insert', args.table, args.obj);
        if (transformer = getTransformer('insert', args.table)) {
          args.obj = objtrans(args.obj, transformer);
        }
      }
      return cb();
    });
    ndx.database.on('preDelete', function(args, cb) {
      if (!args.isServer) {
        check('delete', args.table);
      }
      return cb();
    });
    return ndx.database.permissions = {
      set: function(_permissions) {
        permissions = _permissions;
      }
    };
  };

}).call(this);

//# sourceMappingURL=index.js.map
