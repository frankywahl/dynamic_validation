# frozen_string_literal: true

task :console do
  require "pry"
  require "dynamic_validation"
  ARGV.clear
  Pry.start
end
