module TwitterCldr
  module Tokenizers
    class Base
      attr_reader :resource, :locale
      attr_accessor :type

      def initialize(options = {})
        @locale = options[:locale] || TwitterCldr::DEFAULT_LOCALE
        self.init_resources
        self.init_placeholders
      end

      protected

      def tokens_for(key, type)
        final = []
        tokens = self.expand_pattern(self.pattern_for(self.traverse(key)), type)

        tokens.each do |token|
          if token.is_a?(Token)
            final << token
          else
            final += tokenize_format(token[:value])
          end
        end

        final
      end

      def init_placeholders
        @placeholders = {}
      end

      def traverse(needle, haystack = @resource)
        segments = needle.to_s.split(".")
        final = haystack
        segments.each { |segment| final = final[segment.to_sym] }
        final
      end

      def expand_pattern(format_str, type)
        if format_str.is_a?(Symbol)
          # symbols mean another path was given
          self.expand_pattern(self.pattern_for(self.traverse(format_str)), type)
        else
          parts = tokenize_pattern(format_str)
          final = []

          parts.each do |part|
            case part[:type]
              when :placeholder then
                placeholder = self.choose_placeholder(part[:value], @placeholders)
                final += placeholder ? placeholder.tokens(:type => type) : []
              else
                final << part
            end
          end

          final
        end
      end

      def tokenize_pattern(pattern_str)
        results = []
        pattern_str.split(/(\{\{?\w*\}?\}|\'\w+\')/).each do |piece|
          unless piece.empty?
            case piece[0].chr
              when "{"
                results << { :value => piece, :type => :placeholder }
              else
                results << { :value => piece, :type => :plaintext }
            end
          end
        end
        results
      end

      def choose_placeholder(token, placeholders)
        if token[0..1] == "{{"
          token_value = token[2..-3]
          found = placeholders.find { |placeholder| placeholder[:name].to_s == token_value }
        else
          found = placeholders[token[1..-2].to_i]
        end

        found ? found[:object] : nil
      end
    end
  end
end