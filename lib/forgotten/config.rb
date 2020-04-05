# frozen_string_literal: true

require 'yaml'

module Forgotten
  class Config
    def initialize
      default_config = load_yaml(__dir__, '..', 'config', 'default.yml')
      project_config = load_yaml(Dir.pwd, '.forgotten.yml')

      @config = merge_config(default_config, project_config)
      Array(@config[:gems]).each do |gem|
        @config = merge_config(@config, load_yaml(__dir__, '..', 'config', "#{gem}.yml"))
      end
    end

    def excludes
      Array(@config[:excludes])
    end

    def includes
      Array(@config[:includes])
    end

    def rules
      @rules ||= MethodRule.wrap(@config[:rules])
    end

    def allowed
      @allowed ||= Matcher.new(@config[:allowed])
    end

    private

    def load_yaml(*path)
      file = ::File.join(*path)
      return {} unless ::File.exist?(file)

      YAML.safe_load(::File.read(file), symbolize_names: true)
    rescue Psych::SyntaxError => e
      $stderr.puts "\e[31mError with config #{path.join('/')}: #{e.message}\e[0m"
      exit 1
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
