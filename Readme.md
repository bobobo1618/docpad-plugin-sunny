# Docpad Sunny

So this is another one of the only useful things I've published, yay! Actually distributing my projects is new to me.

Basically, after your [Docpad](https://github.com/bevry/docpad) installation finishes generating the static documents, this plugin is meant to upload them all to Amazon S3 or Google Storage, whichever you select. It uses the apparently awesome library, [Sunny](https://github.com/ryan-roemer/node-sunny). Give Ryan some love.

## Security warning

At the moment, this plugin is written so that people can host generated static Docpad sites on cloud storage. As such, it has `public-read` set as the permission for all uploaded files. Keep this in mind if you're handling private stuff. I'll be adding privacy support in the future.

## Installation

In your Docpad site directory:

- Temporary: `npm install docpad-plugin-sunny`
- Permanent: `npm install --save docpad-plugin-sunny` (should write the dependency to package.json)

## Configuration

There are 4 environment variables that must be configured and 1 optional, that can be.

Mandatory for it to work:

- `DOCPAD_SUNNY_PROVIDER = aws|google`: The cloud storage provider to use. At the moment only Google and Amazon are supported.
- `DOCPAD_SUNNY_ACCOUNT`: The account to use to connect. For Amazon this is the access key, for Google, you get this from the Interoperable Access page under Google Storage in [the console](https://code.google.com/apis/console/)
- `DOCPAD_SUNNY_SECRETKEY`: The key to use. For Amazon, this is the AWS secret key, for Google, this is the Secret found on the page mentioned above.
- `DOCPAD_SUNNY_CONTAINER`: The container to use. a.k.a. bucket.

Optional:

- `DOCPAD_SUNNY_SSL = true|false`: Whether or not to use SSL.

## Running

Generated files will be added to the cloud provider whenever Docpad runs the generate hook.

## Extra

The plugin actually checks each Docpad file for a piece of metadata named `headers`. If you put this field in, you can set up a list of HTTP headers that will be sent with the corresponding request. You can use it to force a mime type, set cache control etc.

## Known bugs

None! :D

## Todo

- Add access control stuff (so people can hide sites).
- Add ability to specify a configuration file as an environment variable.
- Add ability to specify multiple providers and containers.

## License

Do what you want so long as I am credited, I ask that [Ryan Roemer](https://github.com/ryan-roemer) be credited also, since he wrote SunnyJS which does all the real work here. For me, a simple link to [my Github profile](https://github.com/bobobo1618) would suffice.
