#     guv - Scaling governor of cloud workers
#     (c) 2015 The Grid
#     guv may be freely distributed under the MIT license

debug = require('debug')('guv:render')
request = require 'request'
async = require 'async'

exports.dryrun = false

exports.getWorkers = (config, callback) ->
  mainConfig = config['*']
  return callback new Error "Missing global configuration (*)" if not mainConfig

  options =
    url: 'https://api.render.com/v1/services'
    headers:
      'Authorization': "Bearer #{mainConfig.apikey or process.env['RENDER_API_KEY']}"
      'Accept': 'application/json'
    json: true

  request.get options, (err, res, body) ->
    debug 'getservices returned', err, body
    return callback err if err

    workers = []
    for service in body
      w =
        app: service.service.name
        role: service.service.type
        quantity: service.service.numInstances
        id: service.service.id
      workers.push w
    return callback null, workers


exports.setWorkers = (config, workers, callback) ->
  mainConfig = config['*']
  return callback new Error "Missing global configuration (*)" if not mainConfig

  scaleWoker = (worker, cb) ->
    options =
      url: "https://api.render.com/v1/services/#{worker.id}/scale"
      headers:
        'Authorization': "Bearer #{mainConfig.apikey or process.env['RENDER_API_KEY']}"
        'Accept': 'application/json'
      json:
        "numInstances": worker.quantity

    request.post options, (err, res, body) ->
      debug 'scale returned', err, body
      return cb err if err
      cb null, body

  return callback null if exports.dryrun
  debug 'scaling', workers
  async.map workers, scaleWoker, (err, res) ->
    debug 'scaled returned', err, res
    return callback err, res 