# Docpad Sunny

So this is another one of the only useful things I've published, yay! Actually distributing my projects is new to me.

Basically, after your [Docpad](https://github.com/bevry/docpad) installation finishes generating the static documents, this plugin is meant to upload them all to Amazon S3 or Google Storage, whichever you select. It uses the apparently awesome library, [Sunny](https://github.com/ryan-roemer/node-sunny). Give Ryan some love.

## Installation

In your Docpad site directory:

- Temporary: `npm install docpad-plugin-sunny`
- Permanent: `npm install --save docpad-plugin-sunny` (should write the dependency to package.json)

## Configuration

Configuration is mainly set in your Docpad configuration file in the plugins section (look [here](http://bevry.me/docpad/config) for more explanation). The relevant shortname is `sunny`.

The options are:

- `configFromEnv`: Set this to `true` if you want to load configuration from the environment.
- `envPrefixes`: An array of prefixes to try to load environment variables with. (e.g. ["MYAPP_SUNNY_", "YOURAPP_SUNNY_"])
- `cloudConfigs`: An array of objects with the following properties:
    - `sunny`: Another object holding the variables passed to `sunny.Configuration.fromObj`. It has the following properties:
        - `provider`: A string. Can be any provider supported by sunny. At the moment, must be either `aws` or `google`.
        - `account`: A string. The account to use to connect. For Amazon this is the access key, for Google, you get this from the Interoperable Access page under Google Storage in [the console](https://code.google.com/apis/console/)
        - `secretKey`: The key to use. For Amazon, this is the AWS secret key, for Google, this is the Secret found on the page mentioned above.
        - `ssl`: `true` or `false`. Whether or not to use SSL to connect.
        - `authUrl`: A string. The URL of the service to connect to. E.g. `s3.amazonaws.com`
    - `container`: A string containing the name of the container to use.
    - `acl`: ACL to use for all requests. Set to `false` to tell sunny not to send an x-<provider>-acl header. Set to send `public-read` by default.
    - `retryLimit`: Number of times to retry a request. Set to -1 for infinite. Set to 2 by default.
- `onlyIfProduction`: Set to true if you only want to run the plugin in a production (`NODE_ENV=production`) environment. Defaults to true.

An example section from a docpad config:

```coffeescript
[...]
    port: 8000
    enabledPlugins:
        sunny: true # Not necessary, just for reference.
    site:
        [...]
    plugins:
        sunny:
            configFromEnv: true
            envPrefixes: ["DOCPAD_SUNNY_", "DOCPAD_", "MY_AWESOME_APP_SUNNY_"]
            cloudConfigs: [
                {
                    sunny: {
                        provider: 'google'
                        account: 'GOOGOPSDG76978SDG'
                        secretKey: 'SD&*G68S&^DG*&6s8SD'
                        ssl: true
                    }
                    container: 'herpderp.com'
                    acl: 'private'
                },
                {
                    sunny: {
                        provider: 'aws'
                        account: 'ADSDG876SDG87S'
                        secretKey: 'A(*G&(S97*S^DG('
                        ssl: true
                    }
                    container 'meow'
                    acl: false #Uses the policy already set on S3.
                    retryLimit: -1 # Retry as long as is necessary until the upload works.
                }]
[...]
```

This will read two providers from the file (Google and Amazon). Google is set to private reads and Amazon to use whatever the default is on the bucket.

It is also set to pick up configuration from variables with the prefixes `DOCPAD_SUNNY_`, `DOCPAD_`, and `MY_AWESOME_APP_SUNNY_` (so `DOCPAD_SUNNY_ACCOUNT` etc.)


### Environment

There are 4 environment variables per prefix that must be configured and 2 optional, that can be set for SSL.

If no prefixes are set in the main configuration section, the default is `DOCPAD_SUNNY_`

Mandatory for it to work:

- `<PREFIX>PROVIDER = aws|google`: The cloud storage provider to use. At the moment only Google and Amazon are supported.
- `<PREFIX>ACCOUNT`: The account to use to connect. For Amazon this is the access key, for Google, you get this from the Interoperable Access page under Google Storage in [the console](https://code.google.com/apis/console/)
- `<PREFIX>SECRETKEY`: The key to use. For Amazon, this is the AWS secret key, for Google, this is the Secret found on the page mentioned above.
- `<PREFIX>CONTAINER`: The container to use. a.k.a. bucket.

Optional:

- `<PREFIX>SSL = true|false`: Whether or not to use SSL. False by default.
- `<PREFIX>ACL`: The default permissions to use. Set to `public-read` by default. Check the Amazon and [Google](https://developers.google.com/storage/docs/accesscontrol#extension) documentation for details.
- `<PREFIX>RETRY_LIMIT`: Number of times to retry uploads. -1 for infinite. 2 by default.
- `<PREFIX>AUTHURL`: The URL to use. E.g. `s3.amazonaws.com`

## Running

By default, the plugin won't run unless either `NODE_ENV=production` or `onlyIfProduction` is false in the configuration. So either set `onlyIfProduction` to false, run `export NODE_ENV=production` before running docpad or run `NODE_ENV=production docpad generate`.

Generated files will be added to the cloud providers whenever Docpad runs the generate hook.

## Custom headers

The plugin actually checks each Docpad file for a piece of metadata named `headers`. If you put this field in, you can set up a list of HTTP headers that will be sent with the corresponding request. You can use it to force a mime type, set cache control etc.

## Security

Since you may wish to use this in an OSS project such as a blog or somesuch or any real application where you want to distribute source but keep all your keys private, there are two options available for configuration:

- Environment variables (people can't really commit these through Git ;) )
- A separate configuration file put in .gitignore.

## Known bugs

None! :D

## Todo

I did it all :D

## License

Do what you want so long as I am credited, I ask that [Ryan Roemer](https://github.com/ryan-roemer) be credited also, since he wrote SunnyJS which does all the real work here. For me, a simple link to [my Github profile](https://github.com/bobobo1618) would suffice.
