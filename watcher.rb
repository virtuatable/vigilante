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
  path = "#{service.path}#{service.diagnostic}?token=#{vigilante.token}"
  service.instances.each do |instance|
    connection = Faraday.new(url: instance.url) do |faraday|
      faraday.response :logger, logger
      faraday.adapter  Faraday.default_adapter
    end
    tmp_results[instance.id] = begin
      response = connection.get(path) do |req|
        req.options.timeout = 5
      end
      body = response.body
      {
        url: instance.url,
        health: response.status == 200 ? 'ok' : 'ko',
        status: response.status,
        message: JSON.parse(body)
      }
    rescue StandardError
      {
        url: instance.url,
        health: 'ko',
        status: 500,
        message: {type: 'timeout'}
      }
    end
  end
  results[service.key] = tmp_results
end

report = {
  id: vigilante.id,
  persisted: vigilante.persisted?,
  token: vigilante.token,
  results: results
}

puts report.to_json