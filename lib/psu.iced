# Polyfills
require('es6-promise').polyfill()
xhrc = require 'xmlhttprequest-cookie'
global.XMLHttpRequest = xhrc.XMLHttpRequest
xhrc.CookieJar.load '' # Cookies only last the session.

minimist = require 'minimist'
promptly = require 'promptly'
Panoptes = require 'panoptes'
request = require 'request'
path = require 'path'
Baby = require 'babyparse'
fs = require 'fs'
glob = require 'glob'
mime = require 'mime'

putFile = (url, file) ->
  new Promise (resolve, reject) ->
    xhr = new XMLHttpRequest

    xhr.onreadystatechange = (e) =>
      if xhr.readyState is xhr.DONE
        if 200 <= xhr.status < 300
          resolve xhr
        else
          reject xhr

    xhr.open 'PUT', url
    xhr.send file

argOpts =
  alias:
    u: 'username'
    p: 'password'
    r: 'project'
    w: 'workflow'
    # s: 'subject-set', 'subject-set': 'subjectSet'

  default:
    username: process.env.PANOPTES_USERNAME
    password: process.env.PANOPTES_PASSWORD
    project: process.env.PANOPTES_PROJECT
    workflow: process.env.PANOPTES_WORKFLOW

args = minimist process.argv.slice(2), argOpts

unless args.username? then await promptly.prompt 'Username', defer error, args.username
unless args.password? then await promptly.password 'Password', defer error, args.password
unless args.project? then await promptly.prompt 'Project ID', defer error, args.project
unless args.workflow? then await promptly.prompt 'Workflow ID', defer error, args.workflow

console.log 'Args', args

await Panoptes.auth.signIn(display_name: args.username, password: args.password).then(defer user).catch(console.error.bind console)
console.log 'Signed in', user.id

await Panoptes.api.type('workflows').get(args.workflow).then(defer workflow).catch(console.error.bind console)
console.log 'Got workflow', workflow.id

subjectSet = Panoptes.api.type('subject_sets').create
  display_name: 'New subject set (new Date().toISOString())'
  links: project: args.project

await subjectSet.save().then(defer _).catch(console.error.bind console)
console.log 'Created subject set', subjectSet.id

await workflow.addLink('subject_sets', [subjectSet.id]).then(defer _).catch(console.error.bind console)
console.log 'Linked to subject set from workflow'

subjects = []
for file in args._
  file = path.resolve file
  searchDir = path.dirname file

  fileContents = fs.readFileSync(file).toString()
  rows = Baby.parse(fileContents, header: true, dynamicTyping: true).data

  for row, i in rows
    imageFileNames = []
    metadata = {}

    for key, value of row
      metadata[key.trim()] = value.trim?() ? value

      filename = value.match?(/([^\/]+\.(?:jpg|png))/i)?[1]
      if filename?
        matchingFiles = glob.sync path.resolve searchDir, filename.replace /\W/g, '*'
        imageFileNames.push matchingFiles...

    if imageFileNames.length is 0
      console.error "!!! Couldn't find file for row #{i} #{JSON.stringify metadata}"

    else
      subject = Panoptes.api.type('subjects').create
        locations: for imageFileName in imageFileNames
          mime.lookup imageFileName
        metadata: metadata
        links:
          project: args.project

      await subject.save().then(defer _).catch(console.error.bind console)
      subjects.push subject
      console.log 'Saved subject', subject.id

      for typeToURL, i in subject.locations
        url = typeToURL[Object.keys(typeToURL)[0]]
        console.log 'Putting image', imageFileNames[i]
        console.log 'To location', url
        await request.put uri: url, body: fs.readFileSync(imageFileNames[i]).toString(), defer error, _
        await subject.refresh().then(defer _).catch(console.error.bind console)
        console.log 'Put image', JSON.stringify subject.locations

await subjectSet.addLink('subjects', (id for {id} in subjects)).then(defer _).catch(console.error.bind console)
console.log 'Linked subjects to subject set'
