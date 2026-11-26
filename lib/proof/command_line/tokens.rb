# frozen_string_literal: true

module Proof
  module CommandLine
    module Tokens
      def self.flag?(token)
        token.start_with?("-") && token != "-"
      end

      def self.expand(token)
        # OptionParser reads -Cdir as -C with the value dir, where usage reads it as -C -d -i -r and refuses it.
        # Written one letter at a time, each flag reaches OptionParser as usage reads it.
        cluster = token.length > 2 && flag?(token) && !token.start_with?("--")
        cluster ? token.delete_prefix("-").chars.map { |letter| "-#{letter}" } : [token]
      end

      def self.named(flag, tokens)
        # --os=linux is named --os. Tokens.expand writes -q=1 as -q, -=, and -1, so OptionParser refuses -=,
        # which no one typed: the name is the word that expanded to it.
        return flag_name(flag) unless flag == "-="

        typed = tokens.find { |token| expand(token).include?(flag) }
        typed.to_s
      end

      def self.flag_name(token)
        token.split("=").first.to_s
      end

      def self.valued?(token, switches)
        token.start_with?("--") && switches.include?(flag_name(token))
      end

      def self.typed(token, switches)
        name = flag_name(token)
        # A short flag written with "=" is named as typed, as Options names it, since "=" isn't a letter of it. Cut
        # at "=", -=1 would be "-", which no one typed.
        (name == "-" || known?(name, switches)) ? token : name
      end

      def self.known?(token, switches)
        switches.include?(token) || cluster?(token, switches)
      end

      def self.cluster?(token, switches)
        letters = token.delete_prefix("-").chars
        token.length > 2 && !token.start_with?("--") && letters.all? { |letter| switches.include?("-#{letter}") }
      end
    end
  end
end
