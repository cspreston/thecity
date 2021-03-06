require 'forwardable'
require 'uri'

module TheCity
  class Base
    extend Forwardable
    attr_reader :attrs
    alias to_h attrs
    alias to_hash attrs
    alias to_hsh attrs
    def_delegators :attrs, :delete, :update

    # Define methods that retrieve the value from attributes
    #
    # @param attrs [Array, Symbol]
    def self.attr_reader(*attrs)
      for attr in attrs
        define_attribute_method(attr)
        define_predicate_method(attr)
      end
    end

    # Define object methods from attributes
    #
    # @param klass [Symbol]
    # @param key1 [Symbol]
    # @param key2 [Symbol]
    def self.object_attr_reader(klass, key1, key2=nil)
      define_attribute_method(key1, klass, key2)
      define_predicate_method(key1)
    end

    # Define URI methods from attributes
    #
    # @param attrs [Array, Symbol]
    def self.uri_attr_reader(*attrs)
      for uri_key in attrs
        array = uri_key.to_s.split("_")
        index = array.index("uri")
        array[index] = "url"
        url_key = array.join("_").to_sym
        define_uri_method(uri_key, url_key)
        define_predicate_method(uri_key, url_key)
        alias_method(url_key, uri_key)
        alias_method("#{url_key}?", "#{uri_key}?")
      end
    end

    # Dynamically define a method for a URI
    #
    # @param key1 [Symbol]
    # @param key2 [Symbol]
    def self.define_uri_method(key1, key2)
      define_method(key1) do
        memoize(key1) do
          ::URI.parse(@attrs[key2]) if @attrs[key2]
        end
      end
    end

    # Dynamically define a method for an attribute
    #
    # @param key1 [Symbol]
    # @param klass [Symbol]
    # @param key2 [Symbol]
    def self.define_attribute_method(key1, klass=nil, key2=nil)
      define_method(key1) do

        memoize(key1) do
          if klass.nil?
            @attrs[key1]
          else
            if @attrs[key1]
              if key2.nil?
                TheCity.const_get(klass).new(@attrs[key1])
              else
                attrs = @attrs.dup
                value = attrs.delete(key1)
                TheCity.const_get(klass).new(value.update(key2 => attrs))
              end
            else
              TheCity::NullObject.instance
            end
          end
        end
      end
    end

    # Dynamically define a predicate method for an attribute
    #
    # @param key1 [Symbol]
    # @option key2 [Symbol]
    def self.define_predicate_method(key1, key2=key1)
      define_method(:"#{key1}?") do
        !!@attrs[key2]
      end
    end

    # Construct an object from a response hash
    #
    # @param response [Hash]
    # @return [TheCity::Base]
    def self.from_response(response, options)
      new(response[:body], options)
    end

    # Initializes a new object
    #
    # @param attrs [Hash]
    # @return [TheCity::Base]
    def initialize(attrs={}, options={})
      @attrs = attrs || {}
      @client = options.delete(:client) rescue nil
    end

    # Fetches an attribute of an object using hash notation
    #
    # @param method [String, Symbol] Message to send to the object
    def [](method)
      send(method.to_sym)
    rescue NoMethodError
      nil
    end

    def memoize(key, &block)
      ivar = :"@#{key}"
      return instance_variable_get(ivar) if instance_variable_defined?(ivar)
      result = block.call
      instance_variable_set(ivar, result)
    end

  end
end
