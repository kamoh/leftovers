# frozen_string_literal: true

require 'fast_ignore'

module Leftovers
  class FileList < ::FastIgnore
    def initialize
      super(
        ignore_rules: Leftovers.config.exclude_paths,
        include_rules: Leftovers.config.include_paths,
        root: Leftovers.pwd
      )
    end

    def each
      super do |file|
        yield(Leftovers::File.new(file))
      end
    end
  end
end
