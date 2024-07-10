# frozen_string_literal: true

module ActiveRecordTracer
  # @private
  class Reporter
    class << self
      attr_accessor :current
    end

    def initialize(top: 50, backtrace_lines: 5, ignore_cached_queries: false, ignore_schema_queries: true)
      @top = top
      @backtrace_lines = backtrace_lines
      @ignore_cached_queries = ignore_cached_queries
      @ignore_schema_queries = ignore_schema_queries

      @total_runtime = 0.0
      @queries_counts = Hash.new(0)
      @backtrace_queries = Hash.new { |h, k| h[k] = [] }
      @loaded_records = Hash.new(0)
      @loaded_records_backtraces = Hash.new(0)
      @subscriber1 = nil
      @subscriber2 = nil

      @backtraces_cache = {}
    end

    def start
      @subscriber1 = ActiveSupport::Notifications.monotonic_subscribe("sql.active_record") do |_name, start, finish, _id, payload|
        next if payload[:cached] && @ignore_cached_queries
        next if payload[:name] == "SCHEMA" && @ignore_schema_queries

        runtime = finish - start
        @total_runtime += runtime

        sql = payload[:sql].strip
        @queries_counts[sql] += 1

        if @backtrace_lines && @backtrace_lines > 0
          backtrace = query_backtrace(caller(1), @backtrace_lines)
          @backtrace_queries[backtrace] << sql
        end
      end

      @subscriber2 = ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*, payload|
        record_count = payload[:record_count]

        # Active Record erroneously emits notifications even when
        # there are no records https://github.com/rails/rails/pull/52272.
        if record_count > 0
          @loaded_records[payload[:class_name]] += record_count

          if @backtrace_lines && @backtrace_lines > 0
            backtrace = query_backtrace(caller(1), @backtrace_lines)
            @loaded_records_backtraces[backtrace] += record_count
          end
        end
      end
      true
    end

    def stop
      ActiveSupport::Notifications.unsubscribe(@subscriber1)
      ActiveSupport::Notifications.unsubscribe(@subscriber2)

      Report.new(@total_runtime, @queries_counts, @backtrace_queries, @loaded_records,
                 @loaded_records_backtraces, top: @top)
    end

    private
      def query_backtrace(backtrace, limit)
        @backtraces_cache[backtrace] ||=
          if limit && limit > 0
            ActiveRecordTracer.backtrace_cleaner.call(backtrace.lazy).take(limit).to_a
          else
            ActiveRecordTracer.backtrace_cleaner.call(backtrace)
          end
      end
  end
end
