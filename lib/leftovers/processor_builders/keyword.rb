# frozen_string_literal: true

module Leftovers
  module ProcessorBuilders
    module Keyword
      def self.build(value, then_processor)
        return unless value && then_processor

        then_processor = case value
        when true, '**' then then_processor
        when ::String, ::Hash, ::Array
          ::Leftovers::ValueProcessors::IfMatcher.new(
            ::Leftovers::MatcherBuilders::NodeName.build(value), then_processor
          )
        # :nocov:
        else raise Leftovers::UnexpectedCase, "Unhandled value #{value.inspect}"
          # :nocov:
        end

        ::Leftovers::ValueProcessors::EachKeyword.new(then_processor)
      end
    end
  end
end
