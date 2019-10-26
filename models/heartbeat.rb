module Arkaan
  class Heartbeat
    include Mongoid::Document
    include Mongoid::Timestamps

    # @!attribute [rw] status
    #   @return [Integer] the status code of the request to the instance.
    field :status, type: Integer
    # @!attribute [rw] body
    #   @return [String] the request JSON body.
    field :body, type: String

    belongs_to :service, class_name: 'Arkaan::Monitoring::Service'

    belongs_to :instance, class_name: 'Arkaan::Monitoring::Instance'
  end
end