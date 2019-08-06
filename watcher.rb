require 'arkaan'
require 'faraday'

Dotenv.load
Mongoid.load!('config/mongoid.yml', ENV['RACK_ENV'])

results = {}

logger = Logger.new $stderr
logger.level = Logger::ERROR

vigilante = Arkaan::Monitoring::Vigilante.first_or_create(token: ENV['VIGILANTE_TOKEN'])

Arkaan::Monitoring::Service.each do |service|
  tmp_results = {}
  path = "#{service.path}#{service.diagnostic}"
  service.instances.each do |instance|
    connection = Faraday.new(url: instance.url) do |faraday|
      faraday.response :logger, logger
    end
    tmp_results[instance.id] = {
      url: instance.url,
      health: connection.get(path).status == 200 ? 'ok' : 'ko'
    }
  end
  results[service.key] = tmp_results
end

puts results.to_json