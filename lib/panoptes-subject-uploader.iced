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

log = -> console.log '>>>', arguments...

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

await Panoptes.auth.signIn(display_name: args.username, password: args.password).then(defer user).catch(console.error.bind console)
log "Signed in #{user.id} (#{user.display_name})"

await Panoptes.api.type('projects').get(args.project).then(defer project).catch(console.error.bind console)
log "Got project #{project.id} (#{project.display_name})"

await Panoptes.api.type('workflows').get(args.workflow).then(defer workflow).catch(console.error.bind console)
log "Got workflow #{workflow.id} (#{workflow.display_name})"

subjectSet = Panoptes.api.type('subject_sets').create
  display_name: "New subject set #{new Date().toISOString()}"
  links: project: args.project

await subjectSet.save().then(defer _).catch(console.error.bind console)
log "Created subject set #{subjectSet.id} (#{subjectSet.display_name})"

await workflow.addLink('subject_sets', [subjectSet.id]).then(defer _).catch(console.error.bind console)
log 'Linked to subject set from workflow'

getMetadata = (data) ->
  metadata = {}
  for key, value of row
    metadata[key.trim()] = value.trim?() ? value
  metadata

findImages = (searchDir, metadata) ->
  imageFiles = []
  for key, value of metadata
    imageFileName = value.match?(/([^\/]+\.(?:jpg|png))/i)?[1]
    if imageFileName?
      existingImageFile = glob.sync(path.resolve searchDir, imageFileName.replace /\W/g, '?')[0]
      if existingImageFile? and  existingImageFile not in imageFiles
          imageFiles.push existingImageFile
  imageFiles

subjectIDs = []
for file in args._
  file = path.resolve file
  log "Processing #{file}"

  fileContents = fs.readFileSync(file).toString()
  rows = Baby.parse(fileContents, header: true, dynamicTyping: true).data

  for row, i in rows
    log "On row #{i + 1} of #{rows.length}"

    metadata = getMetadata row
    imageFileNames = findImages path.dirname(file), metadata

    if imageFileNames.length is 0
      console.error "!!! Couldn't find an image for row #{i + 1}"

    else
      subject = Panoptes.api.type('subjects').create
        locations: for imageFileName in imageFileNames
          mime.lookup imageFileName
        metadata: metadata
        links:
          project: args.project

      await subject.save().then(defer _).catch(console.error.bind console)
      log "Saved subject #{subject.id}"

      for location, ii in subject.locations
        type = Object.keys(location)[0]
        signedURL = location[type]
        localImageData = fs.readFileSync(imageFileNames[ii]).toString()

        await request.put uri: signedURL, body: localImageData, defer error, _
        log "Put image #{imageFileNames[ii]}"

      # await subject.refresh().then(defer _).catch(console.error.bind console)
      subjectIDs.push subject.id

await subjectSet.addLink('subjects', subjectIDs).then(defer _).catch(console.error.bind console)
log "Linked #{subjectIDs.length} subjects to subject set"
