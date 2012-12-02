# Docpad Sunny

So this is another one of the only useful things I've published, yay! Actually distributing my projects is new to me.

Basically, after your [Docpad](https://github.com/bevry/docpad) installation finishes generating the static documents, this plugin is meant to upload them all to Amazon S3 or Google Storage, whichever you select. It uses the apparently awesome library, [Sunny](https://github.com/ryan-roemer/node-sunny). Give Ryan some love.

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

## Known bugs

None! :D
