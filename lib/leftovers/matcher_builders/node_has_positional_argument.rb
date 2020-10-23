# frozen-string-literal: true

module Leftovers
  module MatcherBuilders
    module NodeHasPositionalArgument
      def self.build(positions, value_matcher) # rubocop:disable Metrics/MethodLength
        if positions && value_matcher
          ::Leftovers::MatcherBuilders::Or.each_or_self(positions) do |position|
            index = position - 1
            ::Leftovers::Matchers::NodeHasPositionalArgumentWithValue.new(index, value_matcher)
          end
        elsif positions
          position = positions.is_a?(Array) ? positions.min : positions

          ::Leftovers::Matchers::NodeHasPositionalArgument.new(position - 1)
        elsif value_matcher
          ::Leftovers::Matchers::NodeHasAnyPositionalArgumentWithValue.new(value_matcher)
        end
      end
    end
  end
end
