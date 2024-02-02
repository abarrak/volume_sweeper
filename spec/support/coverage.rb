require 'simplecov'
require 'simplecov-cobertura'

module SimpleCovHelper
  extend self

  def configure_formatter
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::CoberturaFormatter
      ]
    )
  end
end
