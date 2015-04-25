module.exports = formatJSON=(json)->
  if json? then util = require('util').inspect(json, { depth: 6 })
