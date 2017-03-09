'use strict'

module.exports = () ->
  permissions = {}
  authenticate = null
  check: (op, table, user) ->
    if permissionTable = permissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        if authenticate and authenticate permissionOp
          true
        else
          throw 'Not authorized'
    true
  getTransformer: (op, table, user) ->
    if permissionTable = permissions[table]
      if permissionOp = (permissionTable[op] or permissionTable['all'])
        return permissionOp.transformer
    return
  setPermissions: (_permissions) ->
    permissions = _permissions
    return
  setAuthenticate: (authenticateFn) ->
    authenticate = authenticateFn
    return