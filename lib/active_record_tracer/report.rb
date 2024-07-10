# frozen_string_literal: true

module ActiveRecordTracer
  class Report
    # @private
    def initialize(total_runtime, queries_counts, backtrace_queries, loaded_records, loaded_records_backtraces, top:)
      @total_runtime = total_runtime
      @queries_counts = queries_counts
      @backtrace_queries = backtrace_queries
      @loaded_records = loaded_records
      @loaded_records_backtraces = loaded_records_backtraces
      @top = top
    end

    # Output the results of the report
    #
    # @param to_file [String] a path to your log file
    # @param detailed_report [Boolean] should the report include detailed information
    #
    def pretty_print(io = $stdout, to_file: nil, detailed_report: true)
      # Handle the special case that Ruby PrettyPrint expects `pretty_print`
      # to be a customized pretty printing function for a class.
      return io.pp_object(self) if defined?(PP) && io.is_a?(PP)

      io = File.open(to_file, "w") if to_file

      # Summary stats.
      io.puts("Total runtime: #{@total_runtime.round(2)}s")
      io.puts("Total SQL queries: #{@queries_counts.values.sum}")
      io.puts("Total loaded records: #{total_loaded_records}")
      io.puts

      if detailed_report != false
        # Queries stats.
        print_queries_by_count(io)
        if @backtrace_queries.any?
          print_queries_by_location(io)
          print_queries_by_file(io)
          print_queries_by_backtrace(io)
        end

        # Loaded records stats.
        print_records_by_model(io)
        if @loaded_records_backtraces.any?
          print_records_by_location(io)
          print_records_by_file(io)
          print_records_by_backtrace(io)
        end
      end

      nil
    ensure
      io.close if io.is_a?(File)
    end

    private
      def total_loaded_records
        @loaded_records.values.sum
      end

      def print_queries_by_count(io)
        print_title(io, "Top SQL queries")

        top_query_counts = @queries_counts.sort_by { |_k, v| -v }.take(@top)

        top_query_counts.each do |query, count|
          query.lines.each_with_index do |line, index|
            if index == 0
              io.puts(count.to_s.rjust(8) + "  #{line}")
            else
              io.puts("          #{line}")
            end
          end
          io.puts
        end
      end

      def print_queries_by_location(io)
        print_title(io, "SQL queries by location")

        location_queries = Hash.new(0)
        @backtrace_queries.each do |backtrace, queries|
          location = extract_location(backtrace[0]) || "(internal)"
          location_queries[location] += queries.size
        end

        top_location_queries = location_queries.sort_by { |_k, v| -v }.take(@top)

        top_location_queries.each do |location, queries_count|
          io.puts(queries_count.to_s.rjust(8) + "  #{location}")
        end
        io.puts
      end

      def print_queries_by_file(io)
        print_title(io, "SQL queries by file")

        file_queries = Hash.new(0)
        @backtrace_queries.each do |backtrace, queries|
          file = extract_file(backtrace[0]) || "(internal)"
          file_queries[file] += queries.size
        end

        top_file_queries = file_queries.sort_by { |_k, v| -v }.take(@top)

        top_file_queries.each do |file, queries_count|
          io.puts(queries_count.to_s.rjust(8) + "  #{file}")
        end
        io.puts
      end

      def print_queries_by_backtrace(io)
        print_title(io, "SQL queries by backtrace")

        backtrace_queries = @backtrace_queries.sort_by { |_k, v| -v.size }.take(@top)
        backtrace_queries.each do |backtrace, queries|
          # Backtrace can be empty if it does not contain
          # custom user code and was cleaned.
          next if backtrace.empty?

          print_backtrace(io, queries.size, backtrace)
          io.puts
        end
      end

      def print_records_by_model(io)
        print_title(io, "Loaded records by model")

        model_records = @loaded_records.sort_by { |_k, v| -v }.take(@top)
        model_records.each do |model, records_count|
          io.puts(records_count.to_s.rjust(8) + "  #{model}")
        end
        io.puts
      end

      def print_records_by_location(io)
        print_title(io, "Loaded records by location")

        location_records = Hash.new(0)
        @loaded_records_backtraces.each do |backtrace, records_count|
          location = extract_location(backtrace[0]) || "(internal)"
          location_records[location] += records_count
        end

        top_location_records = location_records.sort_by { |_k, v| -v }.take(@top)

        top_location_records.each do |location, records_count|
          io.puts(records_count.to_s.rjust(8) + "  #{location}")
        end
        io.puts
      end

      def print_records_by_file(io)
        print_title(io, "Loaded records by file")

        file_records = Hash.new(0)
        @loaded_records_backtraces.each do |backtrace, records_count|
          file = extract_file(backtrace[0]) || "(internal)"
          file_records[file] += records_count
        end

        top_file_records = file_records.sort_by { |_k, v| -v }.take(@top)

        top_file_records.each do |file, records_count|
          io.puts(records_count.to_s.rjust(8) + "  #{file}")
        end
        io.puts
      end

      def print_records_by_backtrace(io)
        print_title(io, "Loaded records by backtrace")

        backtrace_records = @loaded_records_backtraces.sort_by { |_k, v| -v }.take(@top)
        backtrace_records.each do |backtrace, records_count|
          # Backtrace can be empty if it does not contain
          # custom user code and was cleaned.
          next if backtrace.empty?

          print_backtrace(io, records_count, backtrace)
          io.puts
        end
      end

      def print_title(io, title)
        io.puts(title)
        io.puts("-----------------------------------")
      end

      def print_backtrace(io, prefix, backtrace)
        backtrace.each_with_index do |line, index|
          if index == 0
            io.puts(prefix.to_s.rjust(8) + "  #{line}")
          else
            io.puts("          #{line}")
          end
        end
      end

      def extract_location(backtrace_line)
        /\A(?<location>.+:\d+):in.+/ =~ backtrace_line
        location || backtrace_line
      end

      def extract_file(backtrace_line)
        /\A(?<file>.+):\d+:in.+/ =~ backtrace_line
        file || backtrace_line
      end
  end
end
