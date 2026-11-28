# frozen_string_literal: true

require "minitest/mock"

# What the tests of the server's folders share: the two variables the server reads, which a test that includes this
# module sees as unset, whatever the real environment holds. The `etcetera` gem reads them from `ENV` itself, with no way
# to hand it another environment, so each test runs with `ENV[]` answering them from `with_xdg`, and answering every
# other name as it does.
module XdgEnvironment
  def run
    @xdg_data = @xdg_config = nil
    real = ENV.method(:[])
    answer = lambda do |name|
      case name
      when "XDG_DATA_HOME" then @xdg_data
      when "XDG_CONFIG_HOME" then @xdg_config
      else real.call(name)
      end
    end
    ENV.stub(:[], answer) { super }
  end

  # Runs the block with `XDG_DATA_HOME` as +data+ and `XDG_CONFIG_HOME` as +config+, and one given as `nil` unset.
  def with_xdg(data: nil, config: nil)
    @xdg_data = data
    @xdg_config = config
    yield
  ensure
    @xdg_data = @xdg_config = nil
  end
end
