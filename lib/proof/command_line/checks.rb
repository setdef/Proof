# frozen_string_literal: true

module Proof
  module CommandLine
    class Checks
      def initialize(command, values)
        @command = command
        @values = values
        path = command.path
        @messages = WordMessages.new(path)
        @flag_messages = Messages.new(path)
      end

      def verify
        @command.groups.each { |group| one_of(group) }
        @command.own_flags.each { |flag| needs(flag) }
      end

      private def one_of(group)
        names = group.names
        given = names.select { |name| @values.given?(name) }
        raise(Mistake, @messages.together(given)) if given.size > 1
        raise(Mistake, @messages.missing_member(names)) if given.empty? && group.required?
      end

      private def needs(flag)
        return unless @values.flag?(flag.name)

        missing = flag.requires.find { |switch| !@values.given?(switch) }
        raise(Mistake, @flag_messages.missing_requirement(flag.switches.last, missing)) if missing
      end
    end
  end
end
