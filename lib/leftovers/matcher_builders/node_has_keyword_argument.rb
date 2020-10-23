# frozen-string-literal: true

module Leftovers
  module MatcherBuilders
    module NodeHasKeywordArgument
      def self.build(keywords, value_matcher)
        value_matcher = ::Leftovers::Matchers::NodePairValue.new(value_matcher) if value_matcher
        keyword_matcher = ::Leftovers::MatcherBuilders::NodeName.build(keywords)
        pair_matcher = ::Leftovers::MatcherBuilders::And.build([keyword_matcher, value_matcher])
        return unless pair_matcher

        ::Leftovers::Matchers::NodeHasAnyKeywordArgument.new(pair_matcher)
      end
    end
  end
end
