url = require('url')

module.exports = buildLink=(base='', href='')->
  url.resolve(base, href)
