# frozen-string-literal: true

require_relative 'path'
require_relative '../matchers/node_path'

module Leftovers
  module MatcherBuilders
    module NodePath
      def self.build(path_pattern)
        matcher = ::Leftovers::MatcherBuilders::Path.build(path_pattern)
        return unless matcher

        ::Leftovers::Matchers::NodePath.new(matcher)
      end
    end
  end
end
