'use strict'

require 'ndx-server'
.config
  database: 'db'
  tables: ['tb1']
.use require '../index'
.use (ndx) ->
  ndx.database.on 'ready', ->
    ndx.database.insert 'tb1',
      mything: 'thing'
.use (ndx) ->
  ndx.user =
    email: 'boop@boop.com'
    roles:
      ADM: true
      "a1": ['yes', 'view']
      "a2": ['no', 'view']
      "a3": ['yes', 'view']
    hasRole: (role) ->
      getKey = (root, key) ->
        root[key]
      keys = role.split /\./g
      allgood = false
      if @roles
        root = @roles
        for key in keys
          root = getKey root, key
          if root
            allgood = true
          else
            allgood = false
            break
      allgood
.use (ndx) ->
  ndx.database.permissions.set
    tb1:
      select: ['sup', 'ADM', 'sap']
.controller (ndx) ->
  ndx.app.get '/', (req, res, next) ->
    ndx.database.select 'tb1', null, (things, total) ->
      res.json things
.start()