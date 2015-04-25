Roa = require('./roa.coffee')

roa = Roa({
  base_url: 'https://json-roa-demo.herokuapp.com/',
  auth: {
    user: process.env.ROA_DEMO_USERNAME
    pass: process.env.ROA_DEMO_PASSWORD
  }
})


roa.getCollection({ href: 'messages/' }, (err, res)-> console.log(err || res))
