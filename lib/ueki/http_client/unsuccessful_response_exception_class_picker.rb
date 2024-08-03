# frozen_string_literal: true

module Ueki
  class HttpClient
    module UnsuccessfulResponseExceptionClassPicker
      def pickup_unsuccessful_response_exception_class(status)
        case status
        when 401
          self.class::UnauthorizedError
        when 403
          self.class::ForbiddenError
        when 404
          self.class::NotFoundError
        when 408
          self.class::RequestTimeoutError
        when 409
          self.class::ConflictError
        when 422
          self.class::UnprocessableEntityError
        when 429
          self.class::TooManyRequestsError
        when 400..499
          self.class::BadRequestError
        when 500..599
          self.class::ServerError
        end
      end
    end
    private_constant :UnsuccessfulResponseExceptionClassPicker
  end
end
