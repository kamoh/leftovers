# frozen-string-literal: true

module Leftovers
  module MatcherBuilders
    module NodeValue
      class << self
        def build(patterns)
          ::Leftovers::MatcherBuilders::Or.each_or_self(patterns) do |pattern|
            case pattern
            when ::Integer, ::Float, true, false
              # matching scalar on nil will fall afoul of compact and each_or_self etc.
              ::Leftovers::Matchers::NodeScalarValue.new(pattern)
            when :_leftovers_nil_value then ::Leftovers::Matchers::NodeType.new(:nil)
            when ::String then ::Leftovers::MatcherBuilders::NodeName.build(pattern)
            when ::Hash then build_from_hash(**pattern)
            # :nocov:
            else raise Leftovers::UnexpectedCase, "Unhandled value #{pattern.inspect}"
              # :nocov:
            end
          end
        end

        private

        def build_node_name_matcher(names, match, has_prefix, has_suffix)
          ::Leftovers::MatcherBuilders::Or.build([
            ::Leftovers::MatcherBuilders::NodeName.build(names),
            ::Leftovers::MatcherBuilders::NodeName.build(
              match: match, has_prefix: has_prefix, has_suffix: has_suffix
            )
          ])
        end

        def build_node_has_argument_matcher(has_arguments, at, has_value)
          ::Leftovers::MatcherBuilders::Or.build([
            ::Leftovers::MatcherBuilders::NodeHasArgument.build(has_arguments),
            ::Leftovers::MatcherBuilders::NodeHasArgument.build(
              at: at, has_value: has_value
            )
          ])
        end

        def build_unless(unless_arg)
          return unless unless_arg

          ::Leftovers::MatcherBuilders::Unless.build(
            ::Leftovers::MatcherBuilders::NodeValue.build(unless_arg)
          )
        end

        def build_from_hash( # rubocop:disable Metrics/ParameterLists
          has_arguments: nil, at: nil, has_value: nil,
          names: nil, match: nil, has_prefix: nil, has_suffix: nil,
          type: nil,
          has_receiver: nil,
          literal: nil,
          unless_arg: nil
        )
          ::Leftovers::MatcherBuilders::And.build([
            build_node_has_argument_matcher(has_arguments, at, has_value),
            build_node_name_matcher(names, match, has_prefix, has_suffix),
            ::Leftovers::MatcherBuilders::NodeType.build(type),
            ::Leftovers::MatcherBuilders::NodeHasReceiver.build(has_receiver),
            ::Leftovers::MatcherBuilders::NodeValue.build(literal),
            build_unless(unless_arg)
          ])
        end
      end
    end
  end
end
