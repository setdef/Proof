# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Node < Data.define(:value)
        # steep:ignore:end
        def text(key)
          String.try_convert(value[key])
        end

        def texts(key)
          list(key).filter_map { |item| String.try_convert(item) }
        end

        def whole_number(key)
          Integer.try_convert(value[key]) || 0
        end

        def true?(key)
          value[key] == true
        end

        def false?(key)
          value[key] == false
        end

        def node(key)
          found = Hash.try_convert(value[key])
          Node.new(found) if found
        end

        def read_all(key, reader)
          list(key).filter_map { |item| reader.new(Node.new(item)) if item.is_a?(Hash) }
        end

        def read_members(key, reader)
          object(key).values.filter_map { |item| reader.new(Node.new(item)) if item.is_a?(Hash) }
        end

        private def list(key)
          Array.try_convert(value[key]) || []
        end

        private def object(key)
          Hash.try_convert(value[key]) || {}
        end
      end
    end
  end
end
