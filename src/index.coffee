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
  checkRoles = (objRoles, userRoles) ->
    for role in userRoles
      if objRoles.indexOf(role) isnt -1
        return true
    return false
  check = (op, args, mypermissions, cb) ->
    args.op = op
    if permissionTable = (mypermissions[args.table] or mypermissions.all)
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
        restPermissions = _permissions
        return
  ndx.permissions =
    #select functions
    anyUser: ->
      (args, cb) ->
        if args.user
          cb true
        else
          cb false
    byId: (idField, id) ->
      (args, cb) ->
        idField = idField or 'user'
        id = id or args.user[ndx.settings.AUTO_ID]
        if args.objs
          i = args.objs.length
          while i-- > 0
            if args.objs[i][idField] isnt id
              args.objs.splice i, 1
          return cb true
        else if args.obj
          if args.obj[idField] isnt id
            return cb false
        cb true
    byUserHasObj: (userField, objField) ->
      objField = objField or ndx.settings.AUTO_ID
      (args, cb) ->
        userField = userField or args.table
        if args.objs
          if args.user[userField]
            i = args.objs.length
            while i-- > 0
              if args.user[userField] isnt args.objs[i][objField]
                args.objs.splice i, 1
          else
            args.objs.length = 0
          return cb true
        else if args.obj
          if args.user[userField]
            if args.user[userField] isnt args.obj[objField]
              return cb false
            else
              return cb true
          else
            return cb false
        return cb true
    byUserHasObjMulti: (userField, objField) ->
      objField = objField or ndx.settings.AUTO_ID
      (args, cb) ->
        userField = userField or args.table
        if args.objs
          if args.user[userField]
            i = args.objs.length
            while i-- > 0
              if not args.user[userField][args.objs[i][objField]]
                args.objs.splice i, 1
          else
            args.objs.length = 0
          return cb true
        else if args.obj
          if args.user[userField]
            if not args.user[userField][args.obj[objField]]
              return cb false
            else
              return cb true
          else
            return cb false
        return cb true
    byUserHasObjRolesMulti: (userField, objField, roles) ->
      objField = objField or ndx.settings.AUTO_ID
      (args, cb) ->
        userField = userField or args.table
        if args.objs
          if args.user[userField]
            i = args.objs.length
            while i-- > 0
              if not args.user[userField][args.objs[i][objField]]
                args.objs.splice i, 1
              else
                if not checkRoles args.user[userField][args.objs[i][objField]]
                  args.objs.splice i, 1
          else
            args.objs.length = 0
          return cb true
        else if args.obj
          if args.user[userField]
            if not args.user[userField][args.obj[objField]]
              return cb false
            else
              if not checkRoles args.user[userField][args.obj[objField]]
                return cb false
              else
                return cb true
          else
            return cb false
        return cb true
    #insert functions
    addObjToUser: (args, cb) ->
      updateObj = {}
      updateObj[args.table] = args.id
      whereObj = {}
      whereObj[ndx.settings.AUTO_ID] = args.user._id
      ndx.database.update ndx.settings.USER_TABLE, updateObj, whereObj, cb
    addObjToUserMulti: (args, cb) ->
      if not args.user[args.table]
        args.user[args.table] = {}
      args.user[args.table][args.id] = true
      updateObj = {}
      updateObj[args.table] = args.user[args.table]
      whereObj = {}
      whereObj[ndx.settings.AUTO_ID] = args.user._id
      ndx.database.update ndx.settings.USER_TABLE, updateObj, whereObj, cb
    