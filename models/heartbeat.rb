module Arkaan
  class Heartbeat
    include Mongoid::Document
    include Mongoid::Timestamps

    field :started_at, type: DateTime
    # @!attribute [rw] ended_at
    #   @return [DateTime] the timestamp at which the heartbeat ends.
    field :ended_at, type: DateTime
    # @!attribute [rw] duration
    #   @return [Integer] the number of milliseconds the heartbeat lasted.
    field :duration, type: Integer
    # @!attribute [rw] status
    #   @return [Integer] the status code of the request to the instance.
    field :status, type: Integer
    # @!attribute [rw] body
    #   @return [String] the request JSON body.
    field :body, type: Hash
    # @!attribute [rw] healthy
    #   @return [Boolean] TRUE if the service is deemed healthy, FALSE otherwise.
    field :healthy, type: Boolean, default: true

    # @!attribute [rw] instance
    #   @return [Arkaan::Monitoring::Service] the monitored instance the heartbeat is linked to.
    belongs_to :instance, class_name: 'Arkaan::Monitoring::Instance'
    # @!attribute [rw] report
    #   @return [Arkaan::Report] the report about the whole infrastructure.
    embedded_in :report, class_name: 'Arkaan::Report', inverse_of: :heartbeats

    def start!
      self.started_at = DateTime.now
    end

    def terminate!
      self.ended_at = DateTime.now
      self.duration = (self.ended_at.strftime('%Q').to_i - self.started_at.strftime('%Q').to_i)
      self.save!
    end
  end
end