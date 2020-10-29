---
category: Tips & Tricks
tags:
  - Rails
  - Postgres
---

# Using Postgres Enum in Rails ActiveRecord

In this post, I will provide some code to make working with an Enum data type
in Postgres easier within your ActiveRecord models. Skip to the end for the
code, or stick around for some verbose pontificating.

## ActiveRecord Enums

ActiveRecord comes with a [handy feature to specify a certain field is an
Enum](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html), or
"Enumerated set of values". However, the documentation emphasizes the simple
way to use it that is fraught with peril. They even note the danger in the
docs:

> Note that when an array is used, the implicit mapping from the values to
> database integers is derived from the order the values appear in the array.
> In the example, :active is mapped to 0 as it's the first element, and
> :archived is mapped to 1. In general, the i-th element is mapped to i-1 in
> the database.
>
> Therefore, once a value is added to the enum array, its position in the array
> must be maintained, and new values should only be added to the end of the
> array. To remove unused values, the explicit hash syntax should be used.

If you use the Array form in your model, like this, it implicitly uses the
position of the item in that array for the integer value for the column in the
database:

```ruby
class Message
  enum state: [
    :queued,     # 0
    :dispatched, # 1
    :delivered   # 2
  ]
end
```

This writes rows to the DB that look like this:

```
 id |  state   |         created_at
----+----------+----------------------------
  1 |        0 | 2020-10-14 21:34:40.036597
  2 |        2 | 2020-10-14 21:34:40.056437
```

However, if you make *any change* to the enum aside from adding a new value to
the end of the Array, then the integer values of the fields change as well.

```ruby
class Message
  enum state: [
    :queued,     # 0
    :dispatched, # 1
    :failed,     # 2
    :delivered   # 3
  ]
end
```

By inserting `:failed` in the middle of the Array, ActiveRecord will now
consider `2` to be "failed" where previously it was "delivered", and so Message
id:2 in our table that used to be "delivered" is now "failed". 💣

However, not all is lost! ActiveRecord Enums may also be defined as a Hash
instead of an Array. That looks like this:

```ruby
class Message
  enum state: {
    queued:     0,
    dispatched: 1,
    delivered:  2
  }
end
```

Now, when we add a new value to the enum, we can put it wherever we want in
that hash, as long as we don't change the numbers.

Its still kinda tedious and annoying, though, that we have to track these
numbers ourselves. It would be nice if we could just store those values
directly as strings in the DB, but that would result in a much larger table,
wasting storage on all those same strings over and over again.

## Leveraging Postgres

The reason why Rails chooses to use Integers as values for its enums is because
it has to support the lowest-common feature set of the databases it supports,
and not all of them support Enums natively. Postgres, however, is [one that
does](https://www.postgresql.org/docs/current/datatype-enum.html), and so if
your app will only ever talk to Postgres, then you can take
advantage of them.

Here's a simple migration to add an enum, we have to drop to raw SQL to
accomplish it:

```ruby
class CreateMessagingTables < ActiveRecord::Migration[6.0]
  reversible do |dir|
    dir.up do
      execute "CREATE TYPE message_state_type AS ENUM ('queued', 'dispatched', 'delivered')"

      create_table :messages do |t|
        t.column :state, :message_state_type, null: false
      end
    end

    dir.down do
      drop_table :messages
      execute "DROP TYPE message_state_type"
    end
  end
end
```

That's gross and annoying, though, so lets extract a helper:

```ruby
# lib/migration_utils.rb

module MigrationUtils
  module CreateEnum
    def create_enum(name, values)
      reversible do |dir|
        dir.up do
          say_with_time "create_enum(:#{name})" do
            suppress_messages do
              execute "CREATE TYPE #{name} AS ENUM (#{values.map{ |v| quote(v) }.join(', ')})"
            end
          end
        end

        dir.down do
          say_with_time "drop_enum(:#{name})" do
            execute "DROP TYPE #{name}"
          end
        end
      end
    end
  end
end

# Then use it in a migration
#
# db/migrations/0000000000_create_messages.rb
class CreateMessagingTables < ActiveRecord::Migration[6.0]
  include MigrationUtils::CreateEnum

  change do
    create_enum :message_state_type, %w[queued dispatched delivered]

    create_table :messages do |t|
      t.column :state, :message_state_type, null: false
    end
  end
end
```

Now we can use Postgres Enum in Rails!

Instead of Integers, Postgres will expose the enum values as Strings, so we need to update the Hash in our model:

```ruby
class Message
  enum state: {
    queued:     :queued,
    dispatched: :dispatched,
    delivered:  :delivered
  }
end
```

The values of the hash must match those of the postgres enum, but the keys can
be whatever you like (but why would you do that to yourself?). Since for our
app, the keys always match the values, we wrote a little helper to remove some
boilerplate:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Provides a bit of syntactic sugar around Rails' built-in enums to map
  # them to postgres enums which expect string values instead of integer
  # values. Basically this saves you from having to pass in:
  # {
  #   foo: "foo",
  #   bar: "bar",
  #   baz: "baz"
  # }
  # to the Rails enum DSL method.
  def self.pg_enum(attribute, values, options = {})
    enum({ attribute => Hash[values.map{ |value| [value.to_sym, value.to_s] }] }.merge(options))
  end
end
```

Now our model looks like this:


```ruby
class Message
  pg_enum state: %i[ queued dispatched delivered ]
end
```

You can find all the code for this, along with helpers to add and remove fields
in the migration, at [this
gist](https://gist.github.com/paul/675d7a3cafca3c05f08a5a1f2aaf19f4)


