# frozen_string_literal: true

module Usage
  class Switch
    def initialize(flag, typed, attached)
      @flag = flag
      @typed = typed
      @attached = attached
    end

    def takes_value?
      @flag.takes_value?
    end

    def read(line)
      return line.take(@flag, @attached || line.value_for(@typed)) if takes_value?

      @attached ? line.refuse { |said| said.needless_value(@typed) } : line.give(@flag)
    end
  end
end
