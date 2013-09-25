require 'the_city/rate_limit'

module TheCity
  # Custom error class for rescuing from all The City API errors
  class Error < StandardError
    attr_reader :rate_limit, :wrapped_exception, :code

    # Create a new error from an HTTP response
    #
    # @param response [Hash]
    # @return [TheCity::Error]
    def self.from_response(response={})
      error, code = parse_error(response[:body])
      new(error, response[:response_headers], code)
    end

    # @return [Hash]
    def self.errors
      @errors ||= descendants.inject({}) do |hash, klass|
        hash[klass::HTTP_STATUS_CODE] = klass
        hash
      end
    end

    # @return [Array]
    def self.descendants
      @descendants ||= []
    end

    # @return [Array]
    def self.inherited(descendant)
      descendants << descendant
    end

    # Initializes a new Error object
    #
    # @param exception [Exception, String]
    # @param response_headers [Hash]
    # @param code [Integer]
    # @return [TheCity::Error]
    def initialize(exception=$!, response_headers={}, code=nil)
      @rate_limit = TheCity::RateLimit.new(response_headers)
      @wrapped_exception = exception
      @code = code
      exception.respond_to?(:message) ? super(exception.message) : super(exception.to_s)
    end

  private

    def self.parse_error(body)
      if body.nil?
        ['', nil]
      elsif body[:error]
        [body[:error], nil]
      elsif body[:errors]
        first = Array(body[:errors]).first
        if first.is_a?(Hash)
          [first[:message].chomp, first[:code]]
        else
          [first.chomp, nil]
        end
      end
    end

  end
end
