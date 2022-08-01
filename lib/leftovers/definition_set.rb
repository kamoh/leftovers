# frozen_string_literal: true

module Leftovers
  class DefinitionSet
    attr_reader :definitions

    def initialize(definitions)
      @definitions = definitions

      freeze
    end

    def names
      @definitions.map(&:names)
    end

    def to_s
      @definitions.map(&:to_s).join(', ')
    end

    def location_s
      if @definitions.first
        @definitions.first.location_s
      else
        puts "NO @definitions.first: @definitions: #{@definitions} - #{self}"
        'zzzz_no_definition_location'
      end
    end

    def highlighted_source(*args)
      if @definitions.first
        @definitions.first.highlighted_source(*args)
      else
        puts "NO @definitions.first: @definitions: #{@definitions}"
        'zzzz_no_highlighted_source'
      end
    end

    def in_collection?
      @definitions.any?(&:in_collection?)
    end

    def test?
      @definitions.any?(&:test?)
    end

    def in_test_collection?
      @definitions.any?(&:in_test_collection?)
    end
  end
end
