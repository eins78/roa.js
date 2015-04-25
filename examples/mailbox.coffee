# alse see test/test.coffe for minimal example

# Fancy Stuff
f = require('lodash')
clc = require('cli-color')
supportsColor = require('supports-color')
moment = require('moment')
HEADER= '\n\n' + '''
███╗   ███╗ █████╗ ██╗██╗     ██████╗  ██████╗ ██╗  ██╗
████╗ ████║██╔══██╗██║██║     ██╔══██╗██╔═══██╗╚██╗██╔╝
██╔████╔██║███████║██║██║     ██████╔╝██║   ██║ ╚███╔╝
██║╚██╔╝██║██╔══██║██║██║     ██╔══██╗██║   ██║ ██╔██╗
██║ ╚═╝ ██║██║  ██║██║███████╗██████╔╝╚██████╔╝██╔╝ ██╗
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

'''
logCLIMessage=(str)-> console.log if supportsColor then clc.green(str) else str
formatDemoMessage=(msg)->
  name = clc.green.bold("@#{msg?.login || 'anonymous'}")
  body = clc.black.bgWhite.bold("\n\n #{msg?.message || '(no content)'} \n ")
  date = moment(msg?.created_at)
  date = clc.blackBright("#{date.fromNow()} on #{date.toJSON()}")
  byline = clc.bgBlue(" #{name} #{date} ")
  formattedPost = "#{byline}#{body}"
  return formattedPost = if supportsColor
    formattedPost + clc.bgBlue(f.repeat('', byline.length)) + '\n'
  else
    clc.strip(formattedPost) + "\n---\n"

logCLIMessage HEADER

# ---
# Actual Demo:
Roa = require('..')  # if using the in-repo (dev) version
# Roa = require('roa') # if using package installed from npm

# give some config:
roaRequest = {
  base_url: 'https://json-roa-demo.herokuapp.com/',
  auth: {
    user: process.env.ROA_DEMO_USERNAME
    pass: process.env.ROA_DEMO_PASSWORD
  }
}

logCLIMessage "> connecting to #{roaRequest.base_url}"
# this just return an object contained functions
# they have access to the config
roa = Roa(roaRequest)

logCLIMessage "> fetching messages/"
# this is the only method right now:
# - fetch a collection by href (and optional query)
# - expanding all item
roa.getCollection { href: 'messages/' }, handleResponse=(err, list)->
  if err? or not list?.map?
    logCLIMessage "< error!"
    return console.log(err || list)

  # finally output the formatted messages:
  logCLIMessage "< received #{list.length} messages \n\n"
  console.log list.map(formatDemoMessage).join('\n')
