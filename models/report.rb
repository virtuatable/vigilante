module Arkaan
  # A report is the result of one monitoring occurrence on the whole infrastructure.
  # @author Vincent Courtois <courtois.vincent@outlook.com>
  class Report
    include Mongoid::Document
    include Mongoid::Timestamps

    field :started_at, type: DateTime
    # @!attribute [rw] ended_at
    #   @return [DateTime] the timestamp at which the report ends.
    field :ended_at, type: DateTime
    # @!attribute [rw] duration
    #   @return [Integer] the number of milliseconds the monitoring lasted.
    field :duration, type: Integer
    # @!attribute [rw] total
    #   @return [Integer] the total number of services monitored.
    field :total, type: Integer, default: 0
    # @!attribute [rw] healthy
    #   @return [Integer] the number of healthy services amongst all the monitored services.
    field :healthy, type: Integer, default: 0

    # @!attribute [rw] heartbeats
    #   @return [Array<Arkaan::Heartbeat>] each call to a service done with this monitoring occurrence.
    embeds_many :heartbeats, class_name: 'Arkaan::Heartbeat', inverse_of: :report

    def add_heartbeat!(heartbeat)
      self.heartbeats << heartbeat
      self.total += 1
      self.healthy += (heartbeat.healthy ? 1 : 0)
      heartbeat.terminate!
    end

    def start!
      self.started_at = DateTime.now
    end

    def terminate!
      self.ended_at = DateTime.now
      self.duration = (self.ended_at.to_datetime.strftime('%Q').to_i - self.started_at.strftime('%Q').to_i)
      self.save!
    end
  end
end
