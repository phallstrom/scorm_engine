require "faraday"
require "faraday_middleware"

module ScormEngine
  module Faraday
    module Connection
      private

      def connection
        @connection ||= ::Faraday.new(url: base_uri.to_s) do |faraday|
          faraday.headers["Content-Type"] = "application/json"
          faraday.headers["User-Agent"] = "ScormEngine Ruby Gem #{ScormEngine::VERSION}"

          faraday.basic_auth(ScormEngine.configuration.username, ScormEngine.configuration.password)

          faraday.request :multipart
          faraday.request :json

          faraday.response :json, :content_type => /\bjson$/
          faraday.response :logger, ScormEngine.configuration.logger, ScormEngine.configuration.log_options

          faraday.adapter ::Faraday.default_adapter
        end
      end

      def base_uri
        uri = URI("")
        uri.scheme = "https" # TODO: Make configurable
        uri.host = ScormEngine.configuration.host
        uri.path = ScormEngine.configuration.path_prefix
        uri
      end
    end
  end
end