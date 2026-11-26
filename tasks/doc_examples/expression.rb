# frozen_string_literal: true

require "prism"

module DocExamples
  # Reads the value a +# =>+ comment gives.
  module Expression
    # Whether +source+ is exactly one Ruby expression. Text that is only a
    # comment, such as +#<Foo>+, is none, and Ruby would read it as +nil+.
    def self.single?(source)
      result = Prism.parse(source)
      result.success? && result.value.statements.body.size == 1
    end
  end
end
