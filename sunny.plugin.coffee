# Yay requires.
sunny = require 'sunny'
mime = require 'mime'
http = require 'http'
util = require 'util'
{TaskGroup} = require('taskgroup')

uploadData = (container, path, headers, data, retryLimit, retries, next)->
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
            uploadData container, path, headers, data, retryLimit, retries+1, next
        writeStream.on 'end', (results, meta)->
            console.log "Uploaded #{path} to #{container.name}"
            next()
        writeStream.write data
        writeStream.end()
    else
        next("Upload for #{path} to #{container.name} has failed #{retries} times. Giving up.")

# Does the upload after Sunny has been set up and such.
doUpload = (docpad, container, acl, retryLimit, next)->
    # Seems obvious enough. Sets files to public read in the cloud.
    if acl?
        if acl is false
            cloudHeaders = {}
        else
            cloudHeaders = {"acl": acl}
    else
        cloudHeaders = {"acl": 'public-read'}
        
    tasks = new TaskGroup().once 'complete', (err) ->
        return next(err)

    docpad.getFiles(write: true).forEach (file)->
        path = file.attributes.relativeOutPath

        # Gets the correct data from Docpad.
        data = file.get('contentRendered') || file.get('content') || (file.getData && file.getData()) || file.getContent() || ""
        if !data
            return next("No data for file #{path}")
        length = data.length
        type = mime.lookup path #file.get('contentType')

        headers = {
            "Content-Length": length,
            "Content-Type": type
        }

        # Merge the headers with those Docpad has.
        try
            if file.get('headers')? #and file.get('headers').length?
                for key, value of file.get('headers')
                    headers[key] = value
        catch err
            console.log err
            console.dir file
        
        tasks.addTask (complete) ->
            uploadData container, path, {headers: headers, cloudHeaders: cloudHeaders}, data, retryLimit, 0, complete
        
    tasks.run()



handle = (docpad, sunnyConfig, sunnyContainer, defaultACL, retryLimit, next)->
    # Test the configuration and try it.
    if sunnyConfig.provider? and sunnyConfig.account? and sunnyConfig.secretKey? and sunnyContainer?
        # Get a connection to the provider.
        connection = sunny.Configuration.fromObj(sunnyConfig).connection
        # Prepare a request to the provider for the container. Checks to make sure the container exists.
        containerReq = connection.getContainer sunnyContainer, {validate: true}

        containerReq.on 'error', (err)->
            console.log "Received error trying to connect to provider: \n #{err}"

        containerReq.on 'end', (results, meta)->
            if results # not sure exactly how, but the 'end' can get called more than once with null params on the second call
                container = results.container
                console.log "Got container #{container.name}."
                # Do the upload.
                doUpload docpad, container, defaultACL, retryLimit, next

        containerReq.end()
    else
        next("""
            One of the config variables is missing. Printing config:
            #{util.inspect(sunnyConfig)}
            Container is #{sunnyContainer}
            """)

handleEnvPrefix = (docpad, prefix, next)->
    sunnyConfig = {
        provider: process.env["#{prefix}PROVIDER"], # Cloud provider: (aws|google)
        account: process.env["#{prefix}ACCOUNT"],
        secretKey: process.env["#{prefix}SECRETKEY"],
        ssl: process.env["#{prefix}SSL"]
        authUrl: process.env["#{prefix}AUTHURL"]
    }
    sunnyContainer = process.env["#{prefix}CONTAINER"]
    sunnyACL = process.env["#{prefix}ACL"]
    sunnyRetryLimit = process.env["#{prefix}RETRY_LIMIT"]

    # Parse the environment variable for ssl.
    sunnyConfig.ssl = ((typeof(sunnyConfig.ssl) is 'string') and (sunnyConfig.ssl.toLowerCase() is 'true'))

    handle docpad, sunnyConfig, sunnyContainer, sunnyACL, sunnyRetryLimit, next

handleEnv = (docpad, config, next)->
    if config.envPrefixes.length > 0
        for prefix in config.envPrefixes
            handleEnvPrefix docpad, prefix, next
    else
        handleEnvPrefix docpad, "DOCPAD_SUNNY_", next

module.exports = (BasePlugin) ->
    class docpadSunnyPlugin extends BasePlugin
        name: "sunny"

        config:
            defaultACL: 'public-read'
            onlyIfProduction: true
            configFromEnv: false
            envPrefixes: []
            cloudConfigs: [
                # {
                #    sunny:{
                #        provider: undefined
                #        account: undefined
                #        secretKey: undefined
                #        ssl: undefined
                #        authUrl: undefined
                #    },
                #    container: undefined,
                #    acl: undefined
                #    retryLimit: undefined
                # }
            ]

        deployWithSunny: (next)=>
            docpad = @docpad
            config = @getConfig()
            
            if config.cloudConfigs.length > 0 or config.configFromEnv
                docpad.log 'info', "Found #{config.cloudConfigs.length} configurations in file."
                @docpad.generate (err)->
                    return next(err) if err

                    tasks = new TaskGroup().once 'complete', (err) ->
                        return next(err)

                    if config.configFromEnv
                        docpad.log 'info', "Grabbing configs from environment."
                        tasks.addTask (complete) ->
                            handleEnv docpad, config, complete

                    for cloudConfig in config.cloudConfigs
                        tasks.addTask (complete) ->
                            handle docpad, cloudConfig.sunny, cloudConfig.container, cloudConfig.acl, cloudConfig.retryLimit, complete
                    tasks.run()
            else
                errMsg = 'No configs found'
                docpad.log 'warn', errMsg
                next(errMsg)

        consoleSetup: (opts)=>
            docpad = @docpad
            config = @getConfig()
            {consoleInterface, commander} = opts

            commander
                .command('deploy-sunny')
                .description("Deploys your website to any provider allowed by Sunny.")
                .action consoleInterface.wrapAction(@deployWithSunny)

            @

        #writeAfter: (opts, next)->
        #    next?()
        #    if (not @config.onlyIfProduction) or (process.env.NODE_ENV is "production")
        #      if @config.configFromEnv
        #          console.log "Sunny plugin getting config from environment..."
        #          handleEnv @docpad, @config
        #
        #      if @config.cloudConfigs.length > 0
        #          console.log "Found #{@config.cloudConfigs.length} configurations in config file."
        #          for cloudConfig in @config.cloudConfigs
        #              handle @docpad, cloudConfig.sunny, cloudConfig.container, cloudConfig.acl, cloudConfig.retryLimit
