# roa.js ★

JSON-ROA client prototype

# Demo

![screenshot](https://cloud.githubusercontent.com/assets/134942/7333283/d1c56694-eb69-11e4-80d6-6c6ad1320c75.png)

```sh
git clone https://github.com/eins78/roa.js roa-js
cd roa-js
npm i
npm run demo
```


# TODO

## Sort out the api:

We dont need to many "classy" stuff, functions are most useful.

Goal: don't distinguish between the `roa_config` and a `roaItem`.

With `jQuery` you can give a literal, a DOM node, or prepared object
and get back the same prepared object with usefull functions.  
In our case it would always just be a ROA object (literal)…

### Ideas:

A really "fluent" (`jQuery`-like) is not possible out of the box
because some (most?) operations are async.

In the real world you are likely to do async stuff as well,
and/or need to process to data in between steps,
so these methods have to be chained with callbacks to.

Promises don't wouldn't help with this because they're basically methods to attach
your callback to.

See below for an example why one object with async functions that run on any roa
object is much easier to handle with the `async` library than a 'fluent' api.


```coffee
roa({ href: api_root }).get (err, root)->
  throw err if err?
  messages = root?.relations.messages?
  err = 'no relation `messages`') unless messages?
  roa(messages).get (err, list)->
    throw err if err?
    list.expand (err, list)->
      throw err if err?
```

or

```coffee
(async.seq
  # naive way to chain it:
  ((callback)-> roa({ href: api_root }).get(callback)),
  ((root, callback)->
    messages = root?.relations.messages?
    err = 'no relation `messages`') unless messages?
    roa(messages).get(callback)),
  ((messages, callback)->
    (roa(messages).expand callback)),
)((err, res)->
  throw err if err?
  (console.log (err || res))
)
```

or

```coffee
(async.seq
  # this is exactly equal to the example before:
  f.curry(roa.get)({ href: api_root }),
  # this dreams up another method:
  f.curry(roa.relation)('messages')
  roa.expand
)((err, res)->
  throw err if err?
  (console.log (err || res))
)
```

Note: the `relation` method is a good example why we always have to run async:
 The first get should not crawl the complete root, but just gets the first page.
 If the relation is not found yet, we need to paginate (or query).
 With collections it should be similar.
