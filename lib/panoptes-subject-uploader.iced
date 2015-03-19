require './polyfills'

minimist = require 'minimist'
promptly = require 'promptly'
Panoptes = require 'panoptes'
request = require 'request'
path = require 'path'
Baby = require 'babyparse'
fs = require 'fs'
glob = require 'glob'
mime = require 'mime'

log = ->
  console.log '>>>', arguments...

getMetadata = (rawData) ->
  metadata = {}
  for key, value of rawData
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

argOpts =
  alias:
    u: 'username'
    p: 'password'
    r: 'project'
    w: 'workflow'
    'subject-set': 'subjectSet'
    h: 'help'

  default:
    username: process.env.PANOPTES_USERNAME
    password: process.env.PANOPTES_PASSWORD
    project: process.env.PANOPTES_PROJECT
    workflow: process.env.PANOPTES_WORKFLOW
    skip: 0 # For debugging, limit the number of rows processed per manifest
    limit: Infinity # For debugging, limit the number of rows processed per manifest
    help: false

args = minimist process.argv.slice(2), argOpts

if args.help or args._.length is 0
  console.log '''
    Usage: panoptes-subject-uploader [options] one/manifest.csv another/manifest.csv

    Required:
      -u, --username "my.login"   Defaults to $PANOPTES_USERNAME
      -p, --password "p@$$w0rd"   Defaults to $PANOPTES_PASSWORD
      -r, --project  "123"        Defaults to $PANOPTES_PROJECT
      -w, --workflow "234"        Defaults to $PANOPTES_WORKFLOW

    Optional:
      --subject-set "345"         If omitted, a new subject set is created
      --skip 50                   Skip the first N lines (per manifest file)
      --limit 100                 Only create N subjects (per manifest file)

    Notes:
      Multiple manifests will end up in the same subject set.
      Images must be in the same directory as their manifests.
  '''
  process.exit 0

unless args.username? then await promptly.prompt 'Username', defer error, args.username
unless args.password? then await promptly.password 'Password', defer error, args.password
unless args.project? then await promptly.prompt 'Project ID', defer error, args.project
unless args.workflow? then await promptly.prompt 'Workflow ID', defer error, args.workflow

await Panoptes.auth.signIn(display_name: args.username, password: args.password).then(defer user).catch(console.error.bind console)
log "Signed in #{user.id} (#{user.display_name})"

await Panoptes.api.type('projects').get("#{args.project}").then(defer project).catch(console.error.bind console)
log "Got project #{project.id} (#{project.display_name})"

await Panoptes.api.type('workflows').get("#{args.workflow}").then(defer workflow).catch(console.error.bind console)
log "Got workflow #{workflow.id} (#{workflow.display_name})"

if args.subjectSet?
  await Panoptes.api.type('subject_sets').get("#{args.subjectSet}").then(defer subjectSet).catch(console.error.bind console)
  log "Using subject set #{subjectSet.id}"
else
  log 'Creating a new subject set'

  subjectSet = Panoptes.api.type('subject_sets').create
    display_name: "New subject set #{new Date().toISOString()}"
    links: project: args.project

  await subjectSet.save().then(defer _).catch(console.error.bind console)
  log "Created subject set #{subjectSet.id} (#{subjectSet.display_name})"

  await workflow.addLink('subject_sets', [subjectSet.id]).then(defer _).catch(console.error.bind console)
  log 'Linked to subject set from workflow'

newSubjectIDs = []

for file in args._
  file = path.resolve file

  fileContents = fs.readFileSync(file).toString().trim()
  rows = Baby.parse(fileContents, header: true, dynamicTyping: true).data

  log "Processing manifest #{file} (#{rows.length} rows)"

  for row, i in rows[args.skip...][...args.limit]
    i += args.skip
    log "On row #{i + 1} of #{rows.length}"

    metadata = getMetadata row
    imageFileNames = findImages path.dirname(file), metadata

    if imageFileNames.length is 0
      console.error "!!! Couldn't find an image for row #{i + 1}"

    else
      subject = Panoptes.api.type('subjects').create
        # Locations are sent as a list of mime types.
        locations: (mime.lookup imageFileName for imageFileName in imageFileNames)
        metadata: metadata
        links:
          project: args.project

      await subject.save().then(defer _).catch(console.error.bind console)
      log "Saved subject #{subject.id}"

      # Locations array has been transformed into [{"mime type": "URL to upload"}]
      for location, ii in subject.locations
        for type, url of location
          headers = {'Content-Type': type}
          body = fs.readFileSync imageFileNames[ii]

          await request.put {headers, url, body}, defer error, response

          unless 200 <= response.statusCode < 400
            error = response.body
          if error?
            console.error '!!! Failed to put image', error
          else
            log "Uploaded image #{imageFileNames[ii]}"

      newSubjectIDs.push subject.id

if newSubjectIDs.length is 0
  log 'No subjects to link'
else
  await subjectSet.addLink('subjects', newSubjectIDs).then(defer _).catch(console.error.bind console)
  log "Linked #{newSubjectIDs.length} subjects to subject set"
