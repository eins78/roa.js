async = require('async')
http_request = require('request')

isString = require('lodash/lang/isString')
isObject = require('lodash/lang/isObject')
isEmpty = require('lodash/lang/isEmpty')

buildLink = require('./buildLink')
formatJSON = require('../formatJSON')

module.exports = RoaHTTPRequest=(config)->

  roaHTTPRequest=(opts, callback)->
    debug('ROA_REQUEST http config', config)
    debug('ROA_REQUEST http opts', opts)

    opts.url = buildLink(config.base_url, opts.href)
    opts.qs = opts.query if isObject(opts.query)

    http_request.defaults(
      method: 'GET'
      json: true
      headers:
        'Accept': 'application/json-roa+json'
        'User-Agent': 'ROA★JS'
      auth: config.auth unless isEmpty(config.auth)
    )(
      opts,
      (err, res, httpStatus)->
        res = res?.body
        debug("ROA_REQUEST http done #{httpStatus} ", err || res)
        callback(err, res)
    )

# helpers
debug=(message, object)->
  # enable debug: `export NODE_DEBUG='roajs'` or even `'request roajs'`
  # (stolen from/compatible with `request` module )
  if (doDebug = process?.env?.NODE_DEBUG?.match?(/\broajs\b/))
    console.log(message, formatJSON(object))
