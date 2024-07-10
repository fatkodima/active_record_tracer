# ActiveRecordTracer

A tracer for Active Record queries

[![Build Status](https://github.com/fatkodima/active_record_tracer/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/fatkodima/active_record_tracer/actions/workflows/test.yml)

You identified (or suspect) that the reason for the slowness of some code is Active Record,
specifically lots of queries and/or loaded records. How do you easily detect which queries,
which records are loaded the most, and the sources of those? This tool to the rescue!

## Requirements

- ruby 3.1+
- activerecord 7.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_record_tracer", group: [:development, :test]
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install active_record_tracer
```

## Usage

```ruby
require "active_record_tracer"
report = ActiveRecordTracer.report do
  # run your code here
end

report.pretty_print
```

Or, you can use the `.start`/`.stop` API as well:

```ruby
require "active_record_tracer"

ActiveRecordTracer.start

# run your code

report = ActiveRecordTracer.stop
report.pretty_print
```

**NOTE**: `.start`/`.stop` can only be run once per report, and `.stop` will
be the only time you can retrieve the report using this API.

### Tracing tests

To trace tests, use the folloding somewhere in the `rails_helper.rb`/`test_helper.rb`:

```ruby
ActiveRecordTracer.start
at_exit do
  report = ActiveRecordTracer.stop
  report.pretty_print(to_file: "tmp/active_record_tracer-tests.txt")
end
```

## Options

### `report`

The `report` method can take a few options:

* `top`: maximum number of entries to display in a report (default is `50`)
* `backtrace_lines`: maximum number of backtrace lines to include in the report (default is `5`)
* `ignore_cached_queries`: whether to ignore cached queries (default is `false`)
* `ignore_schema_queries`: whether to ignore schema queries (default is `true`)

Check out `Reporter#new` for more details.

### `pretty_print`

The `pretty_print` method can take a few options:

* `to_file`: a path to your log file - can be given a String
* `detailed_report`: whether to include detailed information - can be given a Boolean

Check out `Report#pretty_print` for more details.

## Example output

```
Total runtime: 181.36s
Total SQL queries: 8936
Total loaded records: 2648

Top SQL queries
-----------------------------------
     857  SAVEPOINT active_record_1

     856  RELEASE SAVEPOINT active_record_1

     382  SELECT "user_roles".* FROM "user_roles" WHERE "user_roles"."id" = $1 LIMIT $2

     362  SELECT "accounts".* FROM "accounts" WHERE "accounts"."id" = $1 LIMIT $2

     301  INSERT INTO "accounts" ("username", "domain", "private_key") VALUES ($1, $2, $3) RETURNING "id"

     219  SELECT "settings".* FROM "settings" WHERE "settings"."thing_type" IS NULL AND "settings"."thing_id" IS NULL AND "settings"."var" = $1 LIMIT $2

     217  INSERT INTO "conversations" ("uri", "created_at", "updated_at") VALUES ($1, $2, $3) RETURNING "id"

     201  SELECT "statuses".* FROM "statuses" WHERE "statuses"."deleted_at" IS NULL AND "statuses"."id" = $1 ORDER BY "statuses"."id" DESC LIMIT $2

     175  BEGIN

     174  ROLLBACK

     169  SELECT "account_stats".* = $1 LIMIT $2

     158  SELECT 1 AS one FROM "instances" WHERE "instances"."domain" = $1 LIMIT $2

     155  SELECT 1 AS one FROM "users" WHERE "users"."email" = $1 LIMIT $2

     152  SELECT "domain_blocks".* FROM "domain_blocks" WHERE "domain_blocks"."domain" IN ($1, $2) ORDER BY CHAR_LENGTH(domain) DESC LIMIT $3
...

SQL queries by location
-----------------------------------
     586  app/validators/unique_username_validator.rb:12
     391  app/models/user_role.rb:112
     314  app/models/concerns/account/counters.rb:54
     253  app/models/concerns/account/interactions.rb:116
     217  app/models/setting.rb:80
     215  app/models/concerns/status/safe_reblog_insert.rb:19
     168  app/models/concerns/account/counters.rb:48
     165  app/models/domain_block.rb:73
     158  app/models/concerns/domain_materializable.rb:13
     140  app/models/email_domain_block.rb:61
     137  app/models/concerns/database_view_record.rb:8
     123  app/lib/activitypub/activity/create.rb:86
     122  app/lib/activitypub/tag_manager.rb:185
     120  app/models/status.rb:400
     110  app/models/account.rb:375
      98  app/models/concerns/account/finder_concern.rb:32
      98  app/models/concerns/account/finder_concern.rb:16
      87  app/models/status.rb:377
      78  app/models/status.rb:289
      74  app/models/account.rb:150
      68  app/models/follow_request.rb:38
      64  app/services/activitypub/fetch_featured_collection_service.rb:76
      63  app/services/activitypub/process_status_update_service.rb:163
      63  app/models/account.rb:265
      62  app/models/status.rb:371
...

SQL queries by file
-----------------------------------
     586  app/validators/unique_username_validator.rb
     563  app/models/concerns/account/counters.rb
     495  app/models/status.rb
     392  app/models/user_role.rb
     376  app/models/concerns/account/interactions.rb
     340  app/models/account.rb
     337  app/services/activitypub/process_status_update_service.rb
     241  app/models/setting.rb
     217  app/models/concerns/status/safe_reblog_insert.rb
     213  app/lib/activitypub/activity/create.rb
     196  app/models/concerns/account/finder_concern.rb
     166  app/services/fan_out_on_write_service.rb
     165  app/models/domain_block.rb
     158  app/models/concerns/domain_materializable.rb
     155  app/models/email_domain_block.rb
     137  app/models/concerns/database_view_record.rb
     134  app/lib/activitypub/tag_manager.rb
     107  app/models/follow_request.rb
     106  app/lib/feed_manager.rb
...

SQL queries by backtrace
-----------------------------------
     539  app/validators/unique_username_validator.rb:12:in `validate'

     306  app/models/user_role.rb:112:in `everyone'
          app/models/user.rb:160:in `role'
          app/models/user.rb:486:in `sanitize_role'

     168  app/models/concerns/account/interactions.rb:116:in `follow!'

     140  app/models/email_domain_block.rb:61:in `blocking?'
          app/models/email_domain_block.rb:49:in `match?'
          app/models/email_domain_block.rb:94:in `requires_approval?'
          app/models/user.rb:470:in `sign_up_email_requires_approval?'
          app/models/user.rb:416:in `set_approved'

     137  app/models/concerns/domain_materializable.rb:13:in `refresh_instances_view'

     124  app/models/concerns/account/counters.rb:54:in `updated_account_stat'
          app/models/concerns/account/counters.rb:38:in `update_count!'
          app/models/concerns/account/counters.rb:24:in `increment_count!'
          app/models/status.rb:455:in `increment_counter_caches'
...

Loaded records by model
-----------------------------------
     533  Account
     390  UserRole
     287  Status
     101  AccountStat
      70  Setting
      64  User
      29  Follow
      24  AccountDeletionRequest
      21  MediaAttachment
      20  Conversation
      17  FollowRequest
      17  Tag
...

Loaded records by location
-----------------------------------
     381  app/models/user_role.rb:112
      98  app/models/concerns/account/finder_concern.rb:16
      65  app/models/concerns/account/finder_concern.rb:32
      64  app/models/setting.rb:80
      61  app/models/concerns/account/counters.rb:48
      53  app/lib/activitypub/tag_manager.rb:185
      46  app/models/concerns/rate_limitable.rb:23
      45  app/workers/distribution_worker.rb:10
      45  app/services/fan_out_on_write_service.rb:14
...

Loaded records by file
-----------------------------------
     385  app/models/user_role.rb
     163  app/models/concerns/account/finder_concern.rb
      97  app/models/concerns/account/counters.rb
      70  app/models/setting.rb
      68  app/models/account.rb
      57  app/services/fan_out_on_write_service.rb
      53  app/lib/activitypub/tag_manager.rb
...

Loaded records by backtrace
-----------------------------------
     298  app/models/user_role.rb:112:in `everyone'
          app/models/user.rb:160:in `role'
          app/models/user.rb:486:in `sanitize_role'

      61  app/models/setting.rb:80:in `block in []'
          app/models/setting.rb:79:in `[]'
          app/models/setting.rb:65:in `method_missing'
          app/models/user.rb:474:in `open_registrations?'
          app/models/user.rb:419:in `set_approved'

      45  app/services/fan_out_on_write_service.rb:14:in `call'
          app/workers/distribution_worker.rb:10:in `block in perform'
          app/models/concerns/lockable.rb:12:in `block (2 levels) in with_redis_lock'
          app/models/concerns/lockable.rb:10:in `block in with_redis_lock'
          app/lib/redis_configuration.rb:10:in `with'
...
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake test` to run the tests. This project uses multiple Gemfiles to test against multiple versions of Active Record; you can run the tests against the specific version with `BUNDLE_GEMFILE=gemfiles/activerecord_70.gemfile bundle exec rake test`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fatkodima/active_record_tracer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
