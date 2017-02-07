---
category: DataMapper
tags:
 - DataMapper
 - Ruby
---

#Idealized Migration DSL

There's a <a href="http://groups.google.com/group/datamapper/browse_thread/thread/1b24e6f3d7675add">discussion</a> in the datamapper group about how to do migrations. I've thrown together an idealized DSL for how the migrations themselves should look.

Here's the thinking about this, based on how our 2-man web dev team, plus occasionally a few other developers, work on them:

<ul>
<li>
We don't down-migrate in development. We just drop, create & re-migrate the database. In production, we also never have had to down migrate (yet).
</li>
<li>
Occasionally, two developers working in entirely different parts of the system will make a new migration. In default rails, this will create a numbering conflict, and its a pain for the dev that checked in last. Since the two migrations touched different tables, and sometimes even different databases, the versioning isn't helpful. There's plugins to help, using int timestamps, but they're annoying, too. Migrations should be tracked by name, and the system should be smart enough to run any that haven't been run. Versions should be allowed to overlap, with the understanding that overlapping version numbers will be run in any order
</li>
<li>
When using the helpers, like create_table, add_column, etc, the system should be able to figure out the down migration on its own.
</li>
<li>
More often then not, our migrations are written in raw SQL. The helpers are only good for the simplest cases, and we usually want something more complex.
</li>
<li>
These absolutely have to be able to support multiple databases with a minimum of headache.
</li>
</ul>

<h2>Example Migrations</h2>

<pre lang="ruby">
migration 1, :create_people_table do
  up do
    execute "CREATE TABLE people (id serial, name varchar)"
  end
  down do
    execute "DROP TABLE people"
  end
end

migration 2, :add_age_to_people do
  up do
    execute "ALTER TABLE people ADD COLUMN age int"
  end
  down do
    execute "ALTER TABLE people DROP COLUMN age"
  end
end
</pre>

