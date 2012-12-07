# Yay requires.
sunny = require 'sunny'
mime = require 'mime'
http = require 'http'
util = require 'util'

uploadData = (container, path, headers, data, retryLimit, retries)->
    # Test for whether to retry the upload.
    retries = if retries? then retries else 0
    retryLimit = if retryLimit? then retryLimit else 2
    doIt = if not (retryLimit) or (retryLimit and (retries <= retryLimit)) or retryLimit is -1 then true else false

    if doIt
        if retries
            console.log "Retrying upload of #{path} to #{container.name}: Attempts: #{retries}"

        #Open the stream and do the write.
        writeStream = container.putBlob path, headers
        writeStream.on 'error', (err)->
            console.log "Error uploading #{path} to #{container.name}"
            # Recall this function with the retry counter incremented. Yay recursion!
            uploadData container, path, headers, data, retryLimit, retries+1
        writeStream.on 'end', (results, meta)->
            console.log "Uploaded #{path} to #{container.name}"
        writeStream.write data
        writeStream.end()
    else
        console.log "Upload for #{path} to #{container.name} has failed #{retries} times. Giving up."

# Does the upload after Sunny has been set up and such.
doUpload = (docpad, container, acl, retryLimit)->
    # Seems obvious enough. Sets files to public read in the cloud.
    if acl?
        if acl is false
            cloudHeaders = {}
        else
            cloudHeaders = {"acl": acl}
    else
        cloudHeaders = {"acl": 'public-read'}

    docpad.getFiles(write: true).forEach (file)->
        path = file.attributes.relativeOutPath

        # Gets the correct data from Docpad.
        data = file.get('contentRendered') || file.get('content') || file.getData() || file.getContent()
        length = data.length
        type = mime.lookup path #file.get('contentType')

        headers = {
            "Content-Length": length,
            "Content-Type": type
        }

        # Merge the headers with those Docpad has.
        try
            if file.get('headers')? and file.get('headers').length?
                for header in file.get('headers')
                    headers[header.name] = header.value
        catch err
            console.log err
            console.dir file
        uploadData container, path, {headers: headers, cloudHeaders: cloudHeaders}, data, retryLimit



handle = (docpad, sunnyConfig, sunnyContainer, defaultACL, retryLimit)->
    # Test the configuration and try it.
    if sunnyConfig.provider? and sunnyConfig.account? and sunnyConfig.secretKey? and sunnyContainer?
        # Get a connection to the provider.
        connection = sunny.Configuration.fromObj(sunnyConfig).connection
        # Prepare a request to the provider for the container. Checks to make sure the container exists.
        containerReq = connection.getContainer sunnyContainer, {validate: true}

        containerReq.on 'error', (err)->
            console.log "Received error trying to connect to provider: \n #{err}"

        containerReq.on 'end', (results, meta)->
            container = results.container
            console.log "Got container #{container.name}."
            # Do the upload.
            doUpload docpad, container, defaultACL, retryLimit

        containerReq.end()
    else
        console.log 'One of the config variables is missing. Printing config:'
        console.dir sunnyConfig
        console.log "Container is #{sunnyContainer}"

handleEnvPrefix = (docpad, prefix)->
    sunnyConfig = {
        provider: process.env["#{prefix}PROVIDER"], # Cloud provider: (aws|google)
        account: process.env["#{prefix}ACCOUNT"],
        secretKey: process.env["#{prefix}SECRETKEY"],
        ssl: process.env["#{prefix}SSL"]
    }
    sunnyContainer = process.env["#{prefix}CONTAINER"]
    sunnyACL = process.env["#{prefix}ACL"]
    sunnyRetryLimit = process.env["#{prefix}RETRY_LIMIT"]

    # Parse the environment variable for ssl.
    sunnyConfig.ssl = ((typeof(sunnyConfig.ssl) is 'string') and (sunnyConfig.ssl.toLowerCase() is 'true'))

    handle docpad, sunnyConfig, sunnyContainer, sunnyACL, sunnyRetryLimit

handleEnv = (docpad, config)->
    if config.envPrefixes.length > 0
        for prefix in config.envPrefixes
            handleEnvPrefix docpad, prefix
    else
        handleEnvPrefix docpad, "DOCPAD_SUNNY_"

module.exports = (BasePlugin) ->
    class docpadSunyPlugin extends BasePlugin
        name: "sunny"

        config:
            defaultACL: 'public-read'
            configFromEnv: false
            envPrefixes: []
            cloudConfigs: [{
                sunny:{
                    provider: undefined
                    account: undefined
                    secretKey: undefined
                    ssl: undefined
                },
                container: undefined,
                acl: undefined
                retryLimit: undefined
            }]

        writeAfter: (collection)->
            if @config.configFromEnv
                handleEnv @docpad, @config
                console.log 'Grabbing config from environment.'

            if @config.cloudConfigs.length > 0
                for cloudConfig in @config.cloudConfigs
                    handle @docpad, cloudConfig.sunny, cloudConfig.container, cloudConfig.acl, cloudConfig.retryLimit

