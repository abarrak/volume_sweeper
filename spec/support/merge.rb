#!/usr/bin/env ruby
# frozen_string_literal: true


require "simplecov"
require_relative "coverage"

SimpleCovHelper.configure_formatter

resultset_files = Dir.glob(File.join(SimpleCov.coverage_path, '.resultset.json'))
SimpleCov.collate(resultset_files)
