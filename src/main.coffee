#     guv - Scaling governor of cloud workers
#     (c) 2015 The Grid
#     guv may be freely distributed under the MIT license

debug = require('debug')('guv:main')

config = require './config'
governor = require './governor'
newrelic = require './newrelic'
statuspage = require './statuspage'

program = require 'commander'

parse = (argv) ->
  program
    .option('--config <string>', 'Configuration string', String, '')
    .option('--dry-run', 'Configuration string', Boolean, false)
    .option('--oneshot', 'Run once instead of continously', Boolean, false)
    .option('--platform <string>', 'Platform to use (heroku or render)', String, 'render')
    .parse(argv)

exports.main = () ->

  options = parse process.argv
  options.config = process.env['GUV_CONFIG'] if not options.config

  platform = null
  if options.platform == 'heroku'
    platform = require './heroku'
  else if options.platform == 'render'
    platform = require './render'
  else
    throw new Error "Unsupported platform: #{options.platform}"

  platform.dryrun = options['dry-run']
  cfg = config.parse options.config
  guv = new governor.Governor cfg, platform
  newrelic.register guv, cfg
  statuspage.register guv, cfg

  console.log 'Using configuration:\n', options.config

  if options.oneshot
    guv.runOnce (err, state) ->
      throw err if err
      console.log state
  else
    guv.on 'error', (err) ->
      console.log 'ERROR:', err
    guv.start()

