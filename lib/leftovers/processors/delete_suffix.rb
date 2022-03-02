# frozen_string_literal: true

module Leftovers
  module Processors
    class DeleteSuffix
      def initialize(suffix, then_processor)
        @suffix = suffix
        @then_processor = then_processor

        freeze
      end

      def process(str, node, method_node, acc)
        return unless str

        @then_processor.process(str.delete_suffix(@suffix), node, method_node, acc)
      end

      freeze
    end
  end
end