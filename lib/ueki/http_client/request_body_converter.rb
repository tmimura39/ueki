# frozen_string_literal: true

require "json"
require "uri"

module Ueki
  class HttpClient
    module RequestBodyConverter
      module_function

      def call(content_type:, params:)
        return if params.nil?

        case content_type
        when "application/json"
          params&.to_json
        when "application/x-www-form-urlencoded"
          URI.encode_www_form(params)
        else
          params
        end
      end
    end
  end
end
