# frozen_string_literal: true

module Ueki
  class HttpClient
    class ExceptionClassBuilder
      def initialize
        @error = Class.new(StandardError)
        @request_error = build_request_error(@error)
        @timeout_error = Class.new(@request_error)
        @unexpected_error = Class.new(@request_error)
        @unsuccessful_response_error = build_unsuccessful_response_error(@error)
        @bad_request_error = Class.new(@unsuccessful_response_error)
        @unauthorized_error = Class.new(@bad_request_error)
        @forbidden_error = Class.new(@bad_request_error)
        @not_found_error = Class.new(@bad_request_error)
        @request_timeout_error = Class.new(@bad_request_error)
        @conflict_error = Class.new(@bad_request_error)
        @unprocessable_entity_error = Class.new(@bad_request_error)
        @too_many_requests_error = Class.new(@bad_request_error)
        @server_error = Class.new(@unsuccessful_response_error)
      end

      def exception_classes
        {
          Error: @error,
          RequestError: @request_error,
          TimeoutError: @timeout_error,
          UnexpectedError: @unexpected_error,
          UnsuccessfulResponseError: @unsuccessful_response_error,
          BadRequestError: @bad_request_error,
          UnauthorizedError: @unauthorized_error,
          ForbiddenError: @forbidden_error,
          NotFoundError: @not_found_error,
          RequestTimeoutError: @request_timeout_error,
          ConflictError: @conflict_error,
          UnprocessableEntityError: @unprocessable_entity_error,
          TooManyRequestsError: @too_many_requests_error,
          ServerError: @server_error
        }
      end

      private

      def build_request_error(error)
        Class.new(error) do
          def initialize(exception)
            super("#{exception.class.name}: #{exception.message}")
          end
        end
      end

      def build_unsuccessful_response_error(error)
        Class.new(error) do
          attr_reader :status, :body, :headers, :response

          def initialize(message, status:, body:, headers:, response:)
            @status = status
            @body = body
            @headers = headers
            @response = response

            super(message)
          end
        end
      end
    end
    private_constant :ExceptionClassBuilder
  end
end
