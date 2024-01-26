require 'uri'
require 'net/http'

module API
  class Client
    def initialize(host:, port:)
      @host = host
      @port = port
      @base_url = "http://#{@host}:#{@port}"
    end

    def download_plugin_schema(plugin)
      begin
        Net::HTTP.get_response(
          URI("#{@base_url}/schemas/plugins/#{plugin}")
        )
      rescue Errno::ECONNREFUSED => e
        puts e.message
      end
    end

    def validate_plugin(body)
      begin
        Net::HTTP.post(
          URI("#{@base_url}/schemas/plugins/validate"),
          body,
          'Content-Type' => 'application/json'
        )
      rescue Errno::ECONNREFUSED => e
        puts e.message
      end
    end

    def root
      begin
        Net::HTTP.get_response(URI("#{@base_url}/"))
      rescue Errno::ECONNREFUSED => e
        puts e.message
      end
    end
  end
end
