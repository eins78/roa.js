expect = require('must')

# most minimal example without auth
roa=require('..')({
  base_url: 'https://json-roa-demo.herokuapp.com/'
})


roa.get { href: '.' }, handleResponse=(err, list)->
  console.log err
  console.log require('util').inspect(list, { depth: null })

  # we just check that it did not errored:
  expect(err).to.eql(null)
  # there is no collection at this root, but at least that worked:
  expect(list).to.eql({})
