# :nodoc:
require "rubygems"
require 'logger'
require "log4r/outputter/outputter"
require 'bunny'
require 'yaml'

module Log4r
  # See log4r/logserver.rb
  class RabbitOutputter < Outputter

    def initialize(_name, hash={})
      # Configuration defaults
      super(_name, hash)
      @path_to_yaml_file = "#{Rails.root}/config/rabbitmq.yml"
      @config = { username: '', password: '', vhost: '', host: '', queue: '' }
      if File.exist? @path_to_yaml_file
        if @config = YAML::load(IO.read(@path_to_yaml_file))
          @config.symbolize_keys!
          stderr_log @config
          @queue_name = @config.delete :queue
          start_bunny
        else
          stderr_log "Malformed configuration file [#{@path_to_yaml_file}]"
        end
      else
        stderr_log "Unable to find rabbit configuration file [#{@path_to_yaml_file}]"
      end
    end

    def start_bunny
      begin
        stderr_log "Starting Bunny Client"
        conn = Bunny.new @config
        conn.start
        ch = conn.create_channel
        @queue  = ch.queue(@queue_name, auto_delete: false, durable: true)
      rescue Bunny::TCPConnectionFailed => e
        stderr_log "rescued from: #{e}. Unable to connect to Rabbit Server"
      end
    end

    def stderr_log(msg)
      $stderr.puts "[#{Time.now.utc}] #{msg}"
    end
    
    private

      def write(data)
        @queue.publish data, { routing_key: @queue.name } unless @queue.nil?
      end

  end
end
