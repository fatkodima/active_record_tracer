# frozen_string_literal: true

require_relative "active_record_tracer/report"
require_relative "active_record_tracer/reporter"
require_relative "active_record_tracer/version"

module ActiveRecordTracer
  # Helper for running against block and generating a report.
  #
  # @option options [Integer] :top (50) max number of entries to output
  # @option options [Integer, nil] :backtrace_lines (5) max number of backtrace lines
  #   to print. Generating backtrace-related reports is not always needed and can be
  #   costly - set it to '0' or 'nil' to skip it.
  # @option options [Boolean] :ignore_cached_queries (false) whether to ignore cached queries
  # @option options [Boolean] :ignore_schema_queries (true) whether to ignore schema queries
  #
  # @return [ActiveRecordTracer::Report]
  #
  # @example
  #   report = ActiveRecordTracer.report(top: 20) do
  #     # ... generate SQL queries ...
  #   end
  #   report.pretty_print
  #
  def self.report(**options)
    start(**options)
    yield
    stop
  ensure
    stop
  end

  # Start collecting data for the report.
  #
  # @see .report
  # @return [void]
  #
  def self.start(**options)
    unless Reporter.current
      Reporter.current = Reporter.new(**options)
      Reporter.current.start
    end
  end

  # Stop collecting data for the report.
  #
  # @return [ActiveRecordTracer::Report]
  #
  def self.stop
    Reporter.current&.stop
  ensure
    Reporter.current = nil
  end

  # Backtrace cleaner to use when cleaning backtraces.
  #
  # It will use 'Rails.backtrace_cleaner' by default if it is available.
  #
  # @return [Proc]
  #
  def self.backtrace_cleaner
    @backtrace_cleaner ||=
      if defined?(Rails.backtrace_cleaner)
        ->(backtrace) { Rails.backtrace_cleaner.clean(backtrace) }
      else
        ->(backtrace) { backtrace }
      end
  end

  # Set backtrace cleaner to be used when cleaning backtraces.
  #
  # @param value [Proc, ActiveSupport::BacktraceCleaner]
  #
  def self.backtrace_cleaner=(value)
    @backtrace_cleaner =
      if value.is_a?(Proc)
        value
      else
        ->(backtrace) { value.clean(backtrace) }
      end
  end
end
