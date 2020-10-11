# frozen-string-literal: true

require_relative '../matchers/node_scalar_value'
require_relative '../matchers/node_name'
require_relative 'node_name'
require_relative 'node_type'
require_relative 'or'

module Leftovers
  module MatcherBuilders
    module Node
      def self.build(pattern, default) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
        or_matchers = []

        ::Leftovers.each_or_self(pattern) do |pat|
          or_matchers << case pat
          when ::Integer, true, false, nil
            ::Leftovers::Matchers::NodeScalarValue.new(pat)
          when ::String
            ::Leftovers::MatcherBuilders::NodeName.build(pat, nil)
          when ::Hash
            type = ::Leftovers::MatcherBuilders::NodeType.build(pat[:type] || pat[:types], nil)
            not_value = if pat[:not] || pat[:unless]
              ::Leftovers::Matchers::Not.new(
                ::Leftovers::MatcherBuilders::Node.build(pat[:not] || pat[:unless])
              )
            end
            ::Leftovers::MatcherBuilders::And.build([type, not_value], nil)
          end
        end

        ::Leftovers::MatcherBuilders::Or.build(or_matchers, default)
      end
    end
  end
end
