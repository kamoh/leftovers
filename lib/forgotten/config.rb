# frozen_string_literal: true

require 'yaml'

module Forgotten
  class Config
    def initialize
      default_config = load_yaml(__dir__, '..', '.forgotten.yml')
      project_config = load_yaml(Dir.pwd, '.forgotten.yml')

      @config = merge_config(default_config, project_config)
    end

    def ignored
      @config[:ignore]
    end

    def only
      @config[:only]
    end

    def allowed
      @allowed ||= @config[:allowed].map do |pattern|
        # * becomes .*, everything else is rendered inert for regexps. Also it's anchored
        Regexp.new("\\A#{Regexp.escape(pattern).gsub('\\*', '.*')}\\z")
      end
    end

    private

    def load_yaml(*path)
      file = ::File.join(*path)
      return {} unless ::File.exist?(file)

      YAML.safe_load(::File.read(file), symbolize_names: true)
    end

    def merge_config(default, project)
      if project.is_a?(Array) && default.is_a?(Array)
        default | project
      elsif project.is_a?(Hash) && default.is_a?(Hash)
        default.merge(project) { |_k, d, p| merge_config(d, p) }
      else
        project
      end
    end
  end
end