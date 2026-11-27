# frozen_string_literal: true

module Usage
  class Reader
    def initialize(object, where, keys)
      # usage writes `null` for a key it has no value for, so a null is read as a key left out.
      @object = object.compact
      @where = where
      Keys.check(@object, where, keys)
    end

    def name_and_help
      { name: text(:name).to_s, help: text(:help), help_long: text(:help_long) }
    end

    def text(key)
      value = @object.fetch(key) { return }
      value.is_a?(String) ? value : refuse(key, "a string")
    end

    def texts(key)
      list(key).map { |item| item.is_a?(String) ? item : refuse(key, "a list of strings") }
    end

    def boolean(key)
      case (value = @object.fetch(key, false))
      when true, false then value
      else refuse(key, "true or false")
      end
    end

    def false?(key)
      @object[key] == false
    end

    def number(key)
      value = @object[key]
      value.is_a?(Integer) ? value : refuse(key, "a whole number")
    end

    def object(key)
      value = @object.fetch(key) { return {} }
      value.is_a?(Hash) ? value : refuse(key, "an object")
    end

    def nested(key, keys)
      Reader.new(object(key), "#{@where}, in #{key}", keys) if @object.key?(key)
    end

    def parts(key, kind)
      list(key).map { |item| item.is_a?(Hash) ? kind.read(item, @where) : refuse(key, "a list of objects") }
    end

    def members(key)
      object(key).values.map { |item| item.is_a?(Hash) ? item : refuse(key, "an object of objects") }
    end

    private def list(key)
      value = @object.fetch(key, [])
      value.is_a?(Array) ? value : refuse(key, "a list")
    end

    private def refuse(key, form)
      raise(SpecError, "#{@where} has #{key} that isn't #{form}")
    end
  end
end
