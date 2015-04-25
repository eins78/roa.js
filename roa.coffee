async = require('async')
# lodash: optimized imports below, enable full for dev
f = require('lodash')
isString = require('lodash/lang/isString')
isEmpty = require('lodash/lang/isEmpty')
isFunction = require('lodash/lang/isFunction')
merge = require('lodash/object/merge')
# helpers
color=(colorName, string)->
  if doFancy then string.call(colorName) else string

# ---

# The "Roa" part of an API response is embedded in this property:
roaProperty='_json-roa'
getRoa=(obj)-> obj?[roaProperty]
# - `collection` prop
getBody=(obj)-> if obj? then f.omit(obj, roaProperty)
getRoaCollection=(roa)-> roa?['collection']
# - `self-relation` prop
getRoaSelf=(roa)-> roa?['self-relation']
# - `href` prop
getRoaHref=(roa)-> roa?['href']
# - `next` prop
getRoaNext=(roa)-> roa?['next']
# - `relations` prop
getRoaRelations=(roa)-> roa?['relations']
getRoaMethods=(roa)-> roa?['methods']
# - a `RoaItem` is any object with `href` of type string + optional `query`:
getRoaItem=(obj)-> (obj if isString(obj?['href']))

makeRoaResource=(obj)->
  roa_data = getRoa(obj)
  unless roa_data?
    obj
  else
    {
      roa: parseRoaObject(roa_data)
      body: getBody(obj)
    }


parseRoaObject=(roa)->
  self = getRoaSelf(roa)
  relations = getRoaRelations(roa)
  methods = getRoaMethods(roa)

  res = f.pick(roa, 'name')

  res.href = getRoaHref(roa) or getRoaHref(self)

  if self?
    res.self = parseRoaObject(self) if self?

  if relations?
    res.relations = f(relations)
      .map((item, key)-> [key, parseRoaObject(item)])
      .zipObject().value()
  res


# ---

# exports:
module.exports = ROA=(roa_config)->
  # config is expected to be to either a string with the API base or an object
  config = if isString(roa_config) then { base_url: roa_config } else roa_config

  roaHTTPRequest = require('./lib/roaHTTPRequest')(config)

  roaExpandCollection=(roaCollection, callback)->
    if isEmpty(roaCollection)
      return (callback(null, roaCollection) if isFunction(callback))
    async.map f.keys(roaCollection),
      (key, cb)->
        item = roaCollection[key]
        # return item if not a RoaItem
        return cb(null, item) unless getRoaItem(item)?
        # get it and put in the array
        roaHTTPRequest(item, cb)
        # # this would retain original keys… (also see below)
        # roaHTTPRequest item, (err, res)-> cb(err, [key, res])
      ,
      fin=(err, results)->
        callback(err, results)
        # this would retain original keys…
        # callback(err, f.zipObject[results])

  # module returns this object:
  get: (roa, callback)->
    roaHTTPRequest getRoaItem(roa), (err, res)->
      callback(err, makeRoaResource(res))

  getCollection: (roa, callback)->
    # paginated / crawls the whole collection(!) until there are no more items
    roaResult = {}
    currentPage = getRoaItem(roa)
    async.whilst (-> currentPage?),
      (next)->
        roaHTTPRequest currentPage, (err, res)->
          roaCollection = getRoaCollection(getRoa(res))
          roaCollectionRelations = getRoaRelations(roaCollection)
          roaResult = merge({}, roaResult, roaCollectionRelations)
          # > Any of the following two conditions signals the end of the collection for a client:
          # > - The relations object is empty.
          # > - There is no next key.
          nextPage = getRoaNext(roaCollection)
          finished = true if isEmpty(nextPage?) or isEmpty(roaCollectionRelations)
          currentPage = unless finished then nextPage else null
          next(err || null) # no need to return res since we are merging ourselves
      ,
      fin= (err)->
        return callback(err) if err?
        roaExpandCollection roaResult, callback
