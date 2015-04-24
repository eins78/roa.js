async = require('async')
# lodash: optimized imports below, enable full for dev
f = require('lodash')
isString = require('lodash/lang/isString')
# isObject = require('lodash/lang/isObject')
merge = require('lodash/object/merge')
# helpers
color=(colorName, string)->
  if doFancy then string.call(colorName) else string


# exports:
module.exports = ROA=(roa_config)->
  # config is expected to be to either a string with the API base or an object
  config = if isString(roa_config) then { base_url: roa_config } else roa_config

  roaHTTPRequest = require('./lib/roaHTTPRequest')(config)

  roaExpandCollection=(roaCollection, callback)->
    return callback(null, roaCollection) if f.isEmpty(roaCollection)
    async.map f.keys(roaCollection)
      , (key, cb)->
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
  getCollection: roaRequest=(roa, callback)->
    # paginated, runs at least once and as long as they are 'next' links
    roaResult = {}
    currentPage = getRoaItem(roa)
    async.whilst (-> currentPage?),
      (next)->
        roaHTTPRequest currentPage, (err, res)->
          roaCollection = getRoaCollection(getRoa(res))
          roaCollectionRelations = getRoaRelations(roaCollection)
          roaResult = merge({}, roaResult, roaCollectionRelations)
          # > Any of the following two conditions signals the end of the collection for a client:
          # > TODO: - The relations object is empty.
          # > - There is no next key.
          nextPage = getRoaNext(roaCollection)
          currentPage = nextPage
          next(err || null) # no need to return res since we are merging ourselves
      ,
      fin= (err)->
        return callback(err) if err?
        roaExpandCollection roaResult, callback

# ---

# The "Roa" part of an API response is embedded in this property:
roaProperty='_json-roa'
getRoa=(obj)-> obj?[roaProperty]
# - `collection` prop
getRoaCollection=(roa)-> roa?['collection']
# - `next` prop
getRoaNext=(roa)-> roa?['next']
# - `relations` prop
getRoaRelations=(roa)-> roa?['relations']
# - a `RoaItem` is any object with `href` of type string + optional `query`:
getRoaItem=(obj)-> (obj if isString(obj?['href']))
