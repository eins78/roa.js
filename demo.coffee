f = require('lodash')
format = require('./lib/formatJSON')
Roa = require('./roa.coffee')

roa = Roa({
  base_url: 'https://json-roa-demo.herokuapp.com/',
  auth: {
    user: process.env.ROA_DEMO_USERNAME
    pass: process.env.ROA_DEMO_PASSWORD
  }
})


roa.getCollection { href: 'messages/' }
  ,
  (err, res)->
    list = res?.map? (item)-> f.omit(item, '_json-roa')
    console.log(format(err || list || res))
