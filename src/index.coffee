'use strict'

module.exports = (ndx) ->
  permissions = {}
  check = (op, table, obj) ->
    if permissionTable = permissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        if ndx.authenticate and ndx.authenticate permissionOp, obj
          true
        else
          throw 'Not authorized'
    true
  getTransformer = (op, table, obj) ->
    if permissionTable = permissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        return permissionOp.transformer
    return
  ndx.database.on 'preSelect', (args) ->
    if not args.isServer
      check 'select', args.table
  ndx.database.on 'select', (args) ->
    if not args.isServer
      if transformer = getTransformer 'select', args.table
        for item in args.objs
          item = objtrans item, transformer
  ndx.database.on 'preUpdate', (args) ->
    if not args.isServer
      check 'update', args.table, args.obj
      if transformer = getTransformer 'update', args.table
        args.obj = objtrans args.obj, transformer
  ndx.database.on 'preInsert', (args) ->
    if not args.isServer
      check 'insert', args.table, args.obj
      if transformer = getTransformer 'insert', args.table
        args.obj = objtrans args.obj, transformer
  ndx.database.on 'preDelete', (args) ->
    if not args.isServer
      check 'delete', args.table
  ndx.database.permissions = 
    set: (_permissions) ->
      permissions = _permissions
      return