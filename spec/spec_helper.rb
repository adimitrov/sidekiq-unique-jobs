# frozen_string_literal: true

VERSION_REGEX = /(?<operator>[<>=]+)?\s?(?<version>(\d+.?)+)/m
if RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.4.1'
  require 'simplecov'

  begin
    require 'pry'
    require 'byebug'
  rescue LoadError
    puts 'Pry unavailable'
  end
end

require 'rspec'
require 'rspec/its'
require 'awesome_print'

require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq-unique-jobs'
require 'timecop'
require 'sidekiq_unique_jobs/testing'
require 'sidekiq/simulator'

Sidekiq::Testing.disable!
Sidekiq.logger = Logger.new('/dev/null')
SidekiqUniqueJobs.logger.level = Object.const_get("Logger::#{ENV.fetch('LOGLEVEL') { 'error' }.upcase}")

require 'sidekiq/redis_connection'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.filter_run :focus unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

Dir[File.join(File.dirname(__FILE__), 'jobs', '**', '*.rb')].each { |f| require f }

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new" # rubocop:disable Security/Eval
    yield
    result = eval("$#{stream}").string # rubocop:disable Security/Eval
  ensure
    eval("$#{stream} = #{stream.upcase}") # rubocop:disable Security/Eval
  end

  result
end
