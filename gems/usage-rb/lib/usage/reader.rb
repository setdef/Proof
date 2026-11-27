# frozen_string_literal: true

module Usage
  class Reader
    def initialize(object, place, keys)
      # usage writes `null` for a key it has no value for, so a null is read as a key left out.
      @object = object.compact
      @place = place
      keys.check(@object, place)
    end

    def unsupported(what)
      @place.unsupported(what)
    end

    def text(key)
      value = @object.fetch(key) { return }
      value.is_a?(String) ? value : @place.mistyped(key, "a string")
    end

    def texts(key)
      list(key).map { |item| item.is_a?(String) ? item : @place.mistyped(key, "a list of strings") }
    end

    def boolean(key)
      case (value = @object.fetch(key, false))
      when true, false then value
      else @place.mistyped(key, "true or false")
      end
    end

    def false?(key)
      @object.key?(key) && !boolean(key)
    end

    def number(key)
      value = @object[key]
      value.is_a?(Integer) ? value : @place.mistyped(key, "a whole number")
    end

    def object(key)
      value = @object.fetch(key) { return {} }
      value.is_a?(Hash) ? value : @place.mistyped(key, "an object")
    end

    def nested(key, keys)
      Reader.new(object(key), @place.within(key), keys) if @object.key?(key)
    end

    def parts(key, kind)
      list(key).map { |item| item.is_a?(Hash) ? kind.read(item, @place) : @place.mistyped(key, "a list of objects") }
    end

    def members(key)
      object(key).values.map { |item| item.is_a?(Hash) ? item : @place.mistyped(key, "an object of objects") }
    end

    private def list(key)
      value = @object.fetch(key, [])
      value.is_a?(Array) ? value : @place.mistyped(key, "a list")
    end
  end
end
