require './polyfills'

minimist = require 'minimist'
promptly = require 'promptly'
auth = require 'panoptes-client/lib/auth'
apiClient = require 'panoptes-client/lib/api-client'
request = require 'requestretry'
path = require 'path'
Baby = require 'babyparse'
fs = require 'fs'
glob = require 'glob'
mime = require 'mime'
winston = require 'winston'

log = new (winston.Logger)({
  level: 'info',
  transports: [
    new (winston.transports.Console)({ 
      colorize: true,
      humanReadableUnhandledException: true,
      timestamp: true
    }),
    new (winston.transports.File)({ 
      filename: 'panoptes-subject-uploader.log'
      humanReadableUnhandledException: true,
      timestamp: true
    })
  ]
});

getMetadata = (rawData) ->
  metadata = {}
  for key, value of rawData
    metadata[key.trim()] = value.trim?() ? value
  metadata

findImagesFiles = (searchDir, metadata) ->
  imageFiles = []
  for key, value of metadata
    imageFileName = value.match?(/([^\/]+\.(?:jpg|jpeg|gif|png|svg|mp4|txt))/i)?[1]
    if imageFileName?
      existingImageFile = glob.sync(path.resolve searchDir, imageFileName.replace /\W/g, '?')[0]
      if existingImageFile?
        if existingImageFile not in imageFiles
          imageFiles.push existingImageFile
      else
        log.error "!!! Error: Cannot find #{imageFileName} on the local file system."
  imageFiles

findImagesURLs = (metadata) ->
  httpsImageURLs = []
  for key, value of metadata

    httpsRegexPattern = /^(https):\/\//i
    fileRegexPattern = /([^\/]+.(?:jpg|jpeg|gif|png|svg|mp4|txt))$/i

    if fileRegexPattern.test(value)
      if httpsRegexPattern.test(value)
        httpsImageURLs.push value
      else
        log.error "!!! Error: The following url is not HTTPS: #{value}"

  httpsImageURLs

locationCreator = (mimeType, url) ->
  location = {}
  location[mimeType] = url
  location

argOpts =
  alias:
    u: 'username'
    p: 'password'
    r: 'project'
    w: 'workflow'
    'subject-set': 'subjectSet'
    'skip-media-upload': 'skipMediaUpload'
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
      --skip-media-upload         Defaults to false. If set to true, subjects will be created using the urls provided in each row without uploading the associated media.

    Notes:
      Multiple manifests will end up in the same subject set.
      Images must be in the same directory as their manifests.
  '''
  process.exit 0

unless args.username? then await promptly.prompt 'Username', defer error, args.username
unless args.password? then await promptly.password 'Password', defer error, args.password
unless args.project? then await promptly.prompt 'Project ID', defer error, args.project
unless args.workflow? then await promptly.prompt 'Workflow ID', defer error, args.workflow

await auth.signIn(login: args.username, password: args.password).then(defer user).catch(log.error.bind console)
log.info "Signed in #{user.id} (#{user.display_name})"

apiClient.update 'params.admin' : user.admin
log.info "Setting admin flag #{user.admin}"

await apiClient.type('projects').get("#{args.project}").then(defer project).catch(log.error.bind console)
log.info "Got project #{project.id} (#{project.display_name})"

await apiClient.type('workflows').get("#{args.workflow}").then(defer workflow).catch(log.error.bind console)
log.info "Got workflow #{workflow.id} (#{workflow.display_name})"

if args.subjectSet?
  await apiClient.type('subject_sets').get("#{args.subjectSet}").then(defer subjectSet).catch(log.error.bind console)
  log.info "Using subject set #{subjectSet.id}"
else
  log.info 'Creating a new subject set'

  subjectSet = apiClient.type('subject_sets').create
    display_name: "New subject set #{new Date().toISOString()}"
    links: project: args.project

  await subjectSet.save().then(defer _).catch(log.error.bind console)
  log.info "Created subject set #{subjectSet.id} (#{subjectSet.display_name})"

  await workflow.addLink('subject_sets', [subjectSet.id]).then(defer _).catch(log.error.bind console)
  log.info 'Linked to subject set from workflow'

newSubjectIDs = []

for file in args._
  file = path.resolve file

  fileContents = fs.readFileSync(file).toString().trim()
  rows = Baby.parse(fileContents, header: true, dynamicTyping: true).data

  log.info "Processing manifest #{file} (#{rows.length} rows)"

  for row, i in rows[args.skip...][...args.limit]
    i += args.skip
    log.info "On row #{i + 1} of #{rows.length}"

    metadata = getMetadata row
    
    if args.skipMediaUpload
      newSubject = null
      subject = {}
      subject.metadata = metadata
      subject.locations = []
      subject.links = project: args.project
      imageURLs = findImagesURLs metadata
      
      if imageURLs.length is 0
        log.error "!!! Couldn't find an media urls for row #{i + 1}"
      
      locationSuccessCount = 0
      for url, index in imageURLs
        await request url, defer error, response
        
        if error?
          log.error "!!! Error requesting URL for #{url} on row #{i + 1}:", error
        
        if response?
          log.info "The number of attempts to request URL: #{response.attempts}" if response.attempts > 1
          if response.statusCode is 200
            mimeType = mime.lookup url
            subject.locations.push locationCreator(mimeType, url)
            locationSuccessCount++              
          else
            log.error "!!! Error: Unexpected response code:", response.statusCode

      if locationSuccessCount isnt 0 and locationSuccessCount is imageURLs.length
        newSubject = apiClient.type('subjects').create(subject)
        await newSubject.save().then(defer _).catch(log.error.bind console)
        log.info ">> Saved subject #{newSubject.id} for #{imageURLs}"
      
      if newSubject?
        newSubjectIDs.push newSubject.id
      else
        log.error "!!! Error: No subject created."

    # create subject with media upload
    else
      imageFileNames = findImagesFiles path.dirname(file), metadata

      if imageFileNames.length is 0
        log.error "!!! Couldn't find an image for row #{i + 1}"

      else
        subject = apiClient.type('subjects').create
          # Locations are sent as a list of mime types.
          locations: (mime.lookup imageFileName for imageFileName in imageFileNames)
          metadata: metadata
          links:
            project: args.project

        await subject.save().then(defer _).catch(log.error.bind console)
        log.info ">> Saved subject #{newSubject.id} for #{imageURLs}"

        # Locations array has been transformed into [{"mime type": "URL to upload"}]
        successCount = 0
        for location, ii in subject.locations
          for type, url of location
            headers = {'Content-Type': mime.lookup imageFileNames[ii]}
            body = fs.readFileSync imageFileNames[ii]

            await request.put {headers, url, body}, defer error, response

            if response?
              log.info "The number of attempts to upload media: #{response.attempts}" if response.attempts > 1
              if 200 <= response.statusCode < 400
                log.info "Uploaded image #{imageFileNames[ii]}"
                # Deal with multi-image subjects. Track if image upload is successful
                successCount++
              else
                error = response.body

            if error?
              log.error '!!! Failed to put image', error
              log.error "!!! Deleting subject #{subject.id}"
              await subject.delete().then(defer _).catch(log.error.bind console)
              break

          # Deal with multi-image subject. Only add new subject id once and if all images put successfully.
          newSubjectIDs.push subject.id if successCount is subject.locations.length

if newSubjectIDs.length is 0
  log.info 'No subjects to link'
else
  await subjectSet.addLink('subjects', newSubjectIDs).then(defer _).catch(log.error.bind console)
  log.info "Linked #{newSubjectIDs.length} subjects to subject set"
