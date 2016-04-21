#DM Migrations (now with 100% more helpers!)

Added some helpers to the DataMapper Migrations I've been writing. These helpers just build up some SQL, and feed it into #execute.

<pre lang="ruby">
migration 1, :create_people_table do
  up do
    create_table :people do 
      column :name,   :string
      column :gender, :string
    end
  end
  down do
    drop_table :people
  end
end

migration 2, :add_age_and_dob_to_people do
  up do
    modify_table :people do
      add_column :age, :integer
      add_column :dob, :datetime
    end
  end
  down do
    modify_table :people do
      drop_columns :age, :dob
    end
  end
end
</pre>

A caveat: The ALTER TABLE stuff in SQLite is pretty weak. To do anything other than rename the table, or add a column, you have to create a new table with the schema you want, copy the data, then drop the old table. Since these helpers just build the SQL, but don't execute it, I can't run any queries against the table at load time, because some previous migration may have altered the schema in between the load and execution of this one. You're better off just writing the SQL yourself in this case. This is only a factor in SQLite3, though, since Postgres & MySQL support the full ALTER TABLE stuff. In SQLite3, trying to call one of the broken helpers will result in a NotImplemented exception.




