# frozen-string-literal: true

module Leftovers
  module ValueProcessors
    autoload(:AddDynamicPrefix, "#{__dir__}/value_processors/add_dynamic_prefix")
    autoload(:AddDynamicSuffix, "#{__dir__}/value_processors/add_dynamic_suffix")
    autoload(:AddPrefix, "#{__dir__}/value_processors/add_prefix")
    autoload(:AddSuffix, "#{__dir__}/value_processors/add_suffix")
    autoload(:Camelize, "#{__dir__}/value_processors/camelize")
    autoload(:Capitalize, "#{__dir__}/value_processors/capitalize")
    autoload(:Deconstantize, "#{__dir__}/value_processors/deconstantize")
    autoload(:DeleteAfter, "#{__dir__}/value_processors/delete_after")
    autoload(:DeleteBefore, "#{__dir__}/value_processors/delete_before")
    autoload(:DeletePrefix, "#{__dir__}/value_processors/delete_prefix")
    autoload(:DeleteSuffix, "#{__dir__}/value_processors/delete_suffix")
    autoload(:Demodulize, "#{__dir__}/value_processors/demodulize")
    autoload(:Downcase, "#{__dir__}/value_processors/downcase")
    autoload(:EachForDefinitionSet, "#{__dir__}/value_processors/each_for_definition_set")
    autoload(:EachKey, "#{__dir__}/value_processors/each_key")
    autoload(:EachKeywordArgument, "#{__dir__}/value_processors/each_keyword_argument")
    autoload(:EachPositionalArgument, "#{__dir__}/value_processors/each_positional_argument")
    autoload(:Each, "#{__dir__}/value_processors/each")
    autoload(:Itself, "#{__dir__}/value_processors/itself")
    autoload(:KeywordArgument, "#{__dir__}/value_processors/keyword_argument")
    autoload(:Parameterize, "#{__dir__}/value_processors/parameterize")
    autoload(:Placeholder, "#{__dir__}/value_processors/placeholder")
    autoload(:Pluralize, "#{__dir__}/value_processors/pluralize")
    autoload(:PositionalArgument, "#{__dir__}/value_processors/positional_argument")
    autoload(:ReplaceValue, "#{__dir__}/value_processors/replace_value")
    autoload(:ReturnDefinition, "#{__dir__}/value_processors/return_definition")
    autoload(:ReturnString, "#{__dir__}/value_processors/return_string")
    autoload(:Singularize, "#{__dir__}/value_processors/singularize")
    autoload(:Split, "#{__dir__}/value_processors/split")
    autoload(:Swapcase, "#{__dir__}/value_processors/swapcase")
    autoload(:Titleize, "#{__dir__}/value_processors/titleize")
    autoload(:Underscore, "#{__dir__}/value_processors/underscore")
    autoload(:Upcase, "#{__dir__}/value_processors/upcase")
  end
end
