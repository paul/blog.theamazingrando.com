Title: Spec'ing Migrations (A Tutorial)

I realized I haven't blogged about (IMHO) the neatest feature of DataMapper's migrations yet. One of the more harrowing experiences for me in Rails is upgrading a production server with live data, and hoping your migration handles all the existing data correctly. You can dump the database, and attempt the migration on a clone, and hand-examine the data to make sure it was correct, but that feels very non-ruby-like to me. With the spec groups and matchers available in DataMapper migrations, though, you can spec your migrations and be certain that it will work correctly, and translate all your edge-case data correctly.

Lets start off with a simple example. We'll start backwards for this example, but in real life, you're probably better off writing the spec first, then the migration itself, as is normal in iterative development. But regardless, lets say we have the following simple migration we want to spec:

<pre lang="ruby">
migration 1, :create_people_table do
  up do
    create_table :people do
      column :id,     "integer"
      column :name,   "varchar(255)"
      column :age,    "integer"
    end
  end
end
</pre>

Note that I've used string as the column types here. I hope that one day migrations will support dm-types, but until those stabilize post-0.9, I'm not going to try to implement it. Anyways, this just creates a pretty typical `people` table.

Now lets start writing the spec:

<pre lang="ruby">
describe :create_people_table, :type => :migration do

  before do
    run_migration
  end

end
</pre>

Just some boilerplate here. You put the migration name as the name of the `describe` block, and pass the additional option of `:type => :migration`. This informs rspec to run the migration group-specific routines as part of this spec. After that, we have a before block. You must specify the `run_migration` at the end of this block. This allows you to insert any data you want _before_ the migration gets run, so that you can test it got migrated correctly. The way these work is that for every describe block, the database is dropped and recreated, then the migrations run _up_to_ the migration specified. Then the before block is executed, the migration is performed, then the examples are executed. There are some subtle differences between the various DO adapters as to how that all works, but the results are the same.

Alright, lets look at an example now:

<pre lang="ruby">
it 'should create a people table' do
  repository(:default).should have_table(:people)
end
</pre>

Pretty self explanatory, right? Here we use the `#have_table` matcher to check that we do, in fact, have a table called `people`.

How about a more complicated one?

<pre lang="ruby">
it 'should have an id column as the primary key' do
  table(:people).should have_column(:id)
  table(:people).column(:id).type.should == 'integer'
  #table(:people).column(:id).should be_primary_key
end
</pre>

Ah, some meat in this one. Pretty obvious what it does, too. First we check that the `people` table has a column called `id`. Then we look to see that the column's type is 'integer'. (I plan on writing better matchers for these. Right now you have to string-match the column type of your RDBMS. Someday, you will be able to do `column(:id).should have_type(:integer)` or `column(:id).type.should be_integer`. I haven't decided which I like better.) Finally, we check that the column is a primary key. (This matcher hasn't been written yet, either. Feel free to contribute patches to any of this.)

And that's really all there is to it. Take a look at the [sample migration spec]: http://github.com/sam/dm-more/tree/master/dm-migrations/examples/sample_migration_spec.rb to see the whole thing with more examples.

Some things to be aware of
------------------------------
* The matchers don't work at all for MySQL. If anyone wants to contribute, please feel free. Take a look at the postgres & sqlite files under lib/sql/ to see how it should work.
* I couldn't find a way to drop/create a database while inside a DO adapter connection. Rather than trying, I just drop/recreate the 'test' schema inside the database specified in the adapter.
* In Sqlite, I just delete the file, and let the adapter re-create it on its own.
* Postgres is the best-tested, and the most feature-complete. Everything in the examples works on both pg and sqlite. The spec can be initialized in run in mysql, but none of the matchers have been written yet.
