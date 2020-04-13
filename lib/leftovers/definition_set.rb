# frozen_string_literal: true

require_relative 'definition'
module Leftovers
  class DefinitionSet < Leftovers::Definition
    def initialize( # rubocop:disable Metrics/MethodLength
      names,
      method_node: nil,
      location: method_node.loc.expression,
      file: method_node.file,
      test: method_node.test?
    )
      @definitions = names.map do |name|
        Leftovers::Definition.new(name, test: test, location: location, file: file)
      end

      @test = test
      @location = location
      @file = file

      freeze
    end

    def names
      @definitions.map(&:names)
    end

    def to_s
      @definitions.map(&:to_s).join(', ')
    end

    def in_collection?
      @definitions.any?(&:in_collection?)
    end

    def in_test_collection?
      @definitions.any?(&:in_test_collection?)
    end

    def skipped?
      @definitions.any?(&:skipped?)
    end
  end
end
