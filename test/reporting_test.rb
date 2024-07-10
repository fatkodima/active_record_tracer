# frozen_string_literal: true

require "test_helper"
require "tempfile"

class ReportingTest < Minitest::Test
  def test_double_start
    ActiveRecordTracer.start
    previous_reporter = ActiveRecordTracer::Reporter.current
    ActiveRecordTracer.start
    assert_same previous_reporter, ActiveRecordTracer::Reporter.current
  ensure
    ActiveRecordTracer.stop
  end

  def test_stop_without_start
    ActiveRecordTracer.stop
    pass
  end

  def test_prints_summary_stats
    report = ActiveRecordTracer.report do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_match(/Total runtime: \d/, out)
    assert_match(/Total SQL queries: \d/, out)
    assert_match(/Total loaded records: 8/, out)
  end

  def test_prints_queries_stats
    report = ActiveRecordTracer.report do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end

    assert_includes out, "Top SQL queries"
    assert_includes out, '3  SELECT "posts".* FROM "posts" WHERE "posts"."user_id" = ?'
    assert_includes out, '1  SELECT "users".* FROM "users"'

    assert_includes out, "SQL queries by location"
    assert_match(/3  .+test\/sample_class.rb:11/, out)
    assert_match(/1  .+test\/sample_class.rb:5/, out)

    assert_includes out, "SQL queries by file"
    assert_match(/4  .+test\/sample_class.rb/, out)

    assert_includes out, "SQL queries by backtrace"
    assert_match(/3  .+test\/sample_class.rb:11:in `inner'/, out)
    assert_match(/1  .+test\/sample_class.rb:5:in `outer'/, out)
  end

  def test_prints_records_stats
    report = ActiveRecordTracer.report do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end

    assert_includes out, "Loaded records by model"
    assert_includes out, "5  Post"
    assert_includes out, "3  User"

    assert_includes out, "Loaded records by location"
    assert_match(/5  .+test\/sample_class.rb:11/, out)
    assert_match(/3  .+test\/sample_class.rb:5/, out)

    assert_includes out, "Loaded records by file"
    assert_match(/8  .+test\/sample_class.rb/, out)

    assert_includes out, "Loaded records by backtrace"
    assert_match(/5  .+test\/sample_class.rb:11:in `inner'/, out)
    assert_match(/3  .+test\/sample_class.rb:5:in `outer'/, out)
  end

  def test_top_results
    report = ActiveRecordTracer.report do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes out, "SQL queries by location"
    assert_match(/1  .+test\/sample_class.rb:5/, out)

    report = ActiveRecordTracer.report(top: 1) do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    refute_match(/1  .+test\/sample_class.rb:5/, out)
  end

  def test_backtrace_lines
    report = ActiveRecordTracer.report do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes out, "SQL queries by backtrace"
    assert_match(/test\/sample_class.rb:6:in `block in outer'/, out)

    report = ActiveRecordTracer.report(backtrace_lines: 1) do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    refute_match(/test\/sample_class.rb:6:in `block in outer'/, out)
  end

  def test_does_not_print_backtrace_related_reports_if_backtrace_disabled
    report = ActiveRecordTracer.report(backtrace_lines: 0) do
      SampleClass.outer
    end

    out, = capture_io do
      report.pretty_print
    end
    refute_includes out, "SQL queries by backtrace"
  end

  def test_includes_cached_queries_by_default
    report = ActiveRecordTracer.report do
      User.cache do
        User.first
        User.first
      end
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes(out, '2  SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?')
  end

  def test_ignoring_cached_queries
    report = ActiveRecordTracer.report(ignore_cached_queries: true) do
      User.cache do
        User.first
        User.first
      end
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes(out, '1  SELECT "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?')
  end

  def test_ignores_schema_queries_by_default
    report = ActiveRecordTracer.report do
      User.connection.table_exists?("users")
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes out, "Total SQL queries: 0"
  end

  def test_including_schema_queries
    report = ActiveRecordTracer.report(ignore_schema_queries: false) do
      User.connection.table_exists?("users")
    end

    out, = capture_io do
      report.pretty_print
    end
    assert_includes out, "Total SQL queries: 1"
  end

  def test_pretty_print_to_file
    report = ActiveRecordTracer.report do
      User.count
    end

    file = Tempfile.new
    report.pretty_print(to_file: file.path)
    assert_includes file.read, "Total SQL queries: 1"
  ensure
    file.unlink
  end

  def test_skipping_detailed_report
    report = ActiveRecordTracer.report do
      User.count
    end

    out, = capture_io do
      report.pretty_print(detailed_report: false)
    end
    refute_includes out, "SQL queries by backtrace"
  end
end
