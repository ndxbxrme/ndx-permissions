(function() {
  'use strict';
  var async;

  async = require('async');

  module.exports = function(ndx) {
    var check, checkRole, getTransformer, permissions;
    permissions = {};
    checkRole = function(role, args, cb) {
      var truth, type;
      if (!args.user) {
        return cb(true);
      }
      type = Object.prototype.toString.call(role);
      if (type === '[object Array]') {
        truth = false;
        return async.eachSeries(role, function(myroll, callback) {
          if (truth) {
            return callback();
          }
          return checkRole(myroll, args, function(mytruth) {
            truth = truth || mytruth;
            return callback();
          });
        }, function() {
          return cb(truth);
        });
      } else if (type === '[object String]') {
        return cb(args.user.hasRole(role));
      } else if (type === '[object Function]') {
        return role({
          user: args.user,
          objs: args.objs
        }, cb);
      }
    };
    check = function(op, args, cb) {
      var permissionOp, permissionTable;
      if (permissionTable = permissions[args.table]) {
        if (permissionOp = permissionTable[op] || permissionTable['all']) {
          return checkRole(permissionOp.roles || permissionOp, args, function(result) {
            if (result) {
              return cb(result);
            } else {
              throw 'Not authorized';
            }
          });
        } else {
          return cb(true);
        }
      } else {
        return cb(true);
      }
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
      return check('select', args, cb);
    });
    ndx.database.on('select', function(args, cb) {
      return check('select', args, function(result) {
        var i, item, len, ref, transformer;
        if (transformer = getTransformer('select', args.table)) {
          ref = args.objs;
          for (i = 0, len = ref.length; i < len; i++) {
            item = ref[i];
            item = objtrans(item, transformer);
          }
        }
        return cb(true);
      });
    });
    ndx.database.on('preUpdate', function(args, cb) {
      return check('update', args, function(result) {
        var transformer;
        if (transformer = getTransformer('update', args.table)) {
          args.obj = objtrans(args.obj, transformer);
        }
        return cb();
      });
    });
    ndx.database.on('preInsert', function(args, cb) {
      return check('insert', args, function(result) {
        var transformer;
        if (transformer = getTransformer('insert', args.table)) {
          args.obj = objtrans(args.obj, transformer);
        }
        return cb();
      });
    });
    ndx.database.on('preDelete', function(args, cb) {
      return check('delete', args, cb);
    });
    return ndx.database.permissions = {
      set: function(_permissions) {
        permissions = _permissions;
      }
    };
  };

}).call(this);

//# sourceMappingURL=index.js.map
