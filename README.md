# ndx-permissions
### database and socket permissions for ndx-framework  
install with  
`npm install --save ndx-permissions ndx-user-roles`  
`ndx-server` will then auto load the module  
## what it does
`ndx-permissions` adds `.permissions.set()` functions to `ndx.database` and `ndx.rest` (if you have `ndx-rest` installed)  
these functions accept an object that corresponds to the database tables and operations you want to set permissions for  
  
the permissions themselves can be a `String`, `Function` or an array of strings and functions  

```coffeescript
require 'ndx-server'
.config
  tables: ['users']
.use (ndx) ->
  ndx.database.permissions.set
    users:
      select: ['superadmin', 'admin', (args, cb) ->
        if args.objs
          i = args.objs.length
          while i-- > 0
            if args.objs[i]._id isnt args.user._id
              args.objs.splice i, 1
          return cb true
        else if args.obj
          if args.obj._id isnt args.user._id
            return cb false
        cb true
      ]
      all: ['superadmin', 'admin']
.start()
```  
  
  
`ndx.permissions` defines some prebuilt functions to simplify common cases, with these you can rewrite the above as  
```coffeescript
require 'ndx-server'
.config
  tables: ['users']
.use (ndx) ->
  ndx.database.permissions.set
    users:
      select: ['superadmin', 'admin', ndx.permissions.byId()]
      all: ['superadmin', 'admin']
.start()
```  
### select function  
#### `ndx.permissions.anyUser()`
#### `ndx.permissions.byId(idField, id)`
#### `ndx.permissions.byUserHasObj(userField, objField)`
#### `ndx.permissions.byUserHasObjMulti(userField, objField)`
#### `ndx.permissions.byUserHasObjRolesMulti(userField, objField, roles)`
  
since permissions functions recieve the object(s) in question you can use this opportunity to manipulate the data.  
eg. adding the user id on an insert or restricting the fields users with certain permissions can see  
`ndx.permissions` defines a few prebuilt functions to simplify common cases.  
### insert functions
#### `ndx.permissions.addObjToUser(args, cb)`
#### `ndx.permissions.addObjToUserMulti(args, cb)`