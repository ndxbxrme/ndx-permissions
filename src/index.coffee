'use strict'
async = require 'async'

module.exports = (ndx) ->
  permissions = {}
  checkRole = (role, args, cb) ->
    if not args.user
      return cb true
    type = Object.prototype.toString.call role
    if type is '[object Array]'
      truth = false
      async.eachSeries role, (myroll, callback) ->
        if truth
          return callback()
        checkRole myroll, args, (mytruth) ->
          truth = truth or mytruth
          callback()
      , ->
        cb truth
    else if type is '[object String]'
      cb args.user.hasRole role
    else if type is '[object Function]'
      role args
      , cb
  check = (op, args, cb) ->
    if permissionTable = permissions[args.table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        checkRole (permissionOp.roles or permissionOp), args, (result) ->
          if result
            cb result
          else
            throw 'Not authorized'
      else
        cb true
    else
      cb true
  getTransformer = (op, table, obj) ->
    if permissionTable = permissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        return permissionOp.transformer
    return
  ndx.database.on 'preSelect', (args, cb) ->
    check 'select', args, cb
  ndx.database.on 'select', (args, cb) ->
    check 'select', args, (result) ->
      if transformer = getTransformer 'select', args.table
        for item in args.objs
          item = objtrans item, transformer
      cb true
  ndx.database.on 'preUpdate', (args, cb) ->
    check 'update', args, (result) ->
      if transformer = getTransformer 'update', args.table
        args.obj = objtrans args.obj, transformer
      cb()
  ndx.database.on 'preInsert', (args, cb) ->
    check 'insert', args, (result) ->
      if transformer = getTransformer 'insert', args.table
        args.obj = objtrans args.obj, transformer
      cb()
  ndx.database.on 'preDelete', (args, cb) ->
    check 'delete', args, cb
  ndx.database.permissions = 
    set: (_permissions) ->
      permissions = _permissions
      return