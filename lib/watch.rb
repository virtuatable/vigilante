require 'arkaan'
require 'mongoid'
require 'faraday'
require './models/heartbeat.rb'
require './lib/watch.rb'

Dotenv.load
Mongoid.load!('config/mongoid.yml', ENV['RACK_ENV'])

logger = Logger.new $stderr
logger.level = Logger::ERROR

vigilante = Arkaan::Monitoring::Vigilante.first_or_create(token: ENV['VIGILANTE_TOKEN'])

Arkaan::Monitoring::Service.each do |service|
  service.instances.each do |instance|
    results = Arkaan::Heartbeat.new(service: service, instance: instance)
    connection = Faraday.new(url: instance.url) do |faraday|
      faraday.response :logger, logger
      faraday.adapter  Faraday.default_adapter
    end
    begin
      path = "#{service.path}#{service.diagnostic}?token=#{vigilante.token}"
      response = connection.get(path) do |req|
        req.options.timeout = 5
      end
      results.status = response.status
      results.body = response.body
    rescue StandardError
      results.status = 500
      results.body = '{"type": "timeout"}'
    end
    results.save
  end
end