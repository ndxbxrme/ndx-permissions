'use strict'
async = require 'async'

module.exports = (ndx) ->
  dbPermissions = {}
  restPermissions = {}
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
  check = (op, args, mypermissions, cb) ->
    args.op = op
    if permissionTable = mypermissions[args.table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        checkRole (permissionOp.roles or permissionOp), args, (result) ->
          if result
            cb result
          else
            cb false
      else
        cb true
    else
      cb true
  getTransformer = (op, table, mypermissions, obj) ->
    if permissionTable = mypermissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        return permissionOp.transformer
    return
  ndx.database.on 'preSelect', (args, cb) ->
    check 'select', args, dbPermissions, cb
  ndx.database.on 'select', (args, cb) ->
    check 'select', args, dbPermissions, (result) ->
      if result
        if transformer = getTransformer 'select', args.table, dbPermissions
          for item in args.objs
            item = objtrans item, transformer
      cb result
  ndx.database.on 'preUpdate', (args, cb) ->
    check 'update', args, dbPermissions, (result) ->
      if result
        if transformer = getTransformer 'update', args.table, dbPermissions
          args.obj = objtrans args.obj, transformer
      cb result
  ndx.database.on 'preInsert', (args, cb) ->
    check 'insert', args, dbPermissions, (result) ->
      if result
        if transformer = getTransformer 'insert', args.table, dbPermissions
          args.obj = objtrans args.obj, transformer
      cb result
  ndx.database.on 'preDelete', (args, cb) ->
    check 'delete', args, dbPermissions, cb
  ndx.database.permissions = 
    set: (_permissions) ->
      dbPermissions = _permissions
      return
  if ndx.rest
    ndx.rest.on 'update', (args, cb) ->
      check 'update', args, restPermissions, cb
    ndx.rest.on 'insert', (args, cb) ->
      check 'insert', args, restPermissions, cb
    ndx.rest.on 'delete', (args, cb) ->
      check 'delete', args, restPermissions, cb
    ndx.rest.permissions =
      set: (_permissions) ->
        dbPermissions = _permissions
        return