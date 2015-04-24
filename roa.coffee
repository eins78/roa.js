# core:
url = require('url')
# npm:
async = require('async')
http_request = require('request')
# lodash: optimized imports below, enable full for dev
f = require('lodash')
isString = require('lodash/lang/isString')
isObject = require('lodash/lang/isObject')
merge = require('lodash/object/merge')

# exports:
module.exports = ROA=(roa_config)->
  # config is expected to be to either a string with the API base or an object
  cfg = if isString(roa_config) then { apiUrl: roa_config } else roa_config

  roaHTTPRequest=(opts, callback)->
    debug('ROA_REQUEST http config', cfg)
    debug('ROA_REQUEST http opts', opts)
    # handle (href -> url), resolve with API base_url
    opts.url = url.resolve(cfg.apiUrl, opts.href) if isString(opts.href)
    opts.qs = opts.query if isObject(opts.query)
    http_request.defaults(
      method: 'GET'
      json: true
      headers:
        'Accept': 'application/json-roa+json'
        'User-Agent': 'ROA★JS'
      auth:
        user: process.env['CIDER_CI_USERNAME']
        pass: process.env['CIDER_CI_PASSWORD']
        sendImmediately: false
    )(
      opts,
      (err, res, httpStatus)->
        res = res?.body
        debug('ROA_REQUEST', err || res)
        callback(err, res)
    )

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

# ---

# helpers
debug=(message, objects)->
  # enable debug: `export NODE_DEBUG='json_roa'` or even `'request json_roa'`
  # (stolen from/compatible with `request` module )
  doDebug = process?.env?.NODE_DEBUG && /\bjson_roa\b/.test(process.env.NODE_DEBUG)
  if doDebug then console.log(message, objects) else null

color=(colorName, string)->
  if doFancy then string.call(colorName) else string
