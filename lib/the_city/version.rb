module TheCity
  class Version
    MAJOR = 0
    MINOR = 0
    PATCH = 9
    PRE = nil

    class << self

      # @return [String]
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join('.')
      end

    end

  end
end
