require 'arkaan'
require 'mongoid'
require 'faraday'
require './models/heartbeat.rb'
require './models/report.rb'

Dotenv.load
Mongoid.load!('config/mongoid.yml', ENV['RACK_ENV'])

logger = Logger.new $stderr
logger.level = Logger::ERROR

vigilante = Arkaan::Monitoring::Vigilante.first_or_create(token: ENV['VIGILANTE_TOKEN'])

report = Arkaan::Report.new
report.start!

Arkaan::Monitoring::Service.each do |service|
  service.instances.each do |instance|
    heartbeat = Arkaan::Heartbeat.new(instance: instance)
    heartbeat.start!

    connection = Faraday.new(url: instance.url) do |faraday|
      faraday.response :logger, logger
      faraday.adapter  Faraday.default_adapter
    end

    begin
      path = "#{service.path}#{service.diagnostic}?token=#{vigilante.token}"

      response = connection.get(path) do |req|
        req.options.timeout = 5
      end
      heartbeat.status = response.status
      heartbeat.body = JSON.parse(response.body)
      heartbeat.healthy = response.status == 200 && heartbeat.body['health'] == 'ok' rescue false
    rescue StandardError
      heartbeat.status = 500
      heartbeat.body = '{"type": "timeout"}'
      heartbeat.healthy = false
    end
    report.add_heartbeat!(heartbeat)
  end
end

report.terminate!