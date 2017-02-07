---
category: DataMapper
tags:
 - DataMapper
 - Ruby

---

#A Response to "Database Versioning"

I was just going to post a comment in reply to [Adam Wiggins's Database Versioning post](http://adam.blog.heroku.com/past/2009/3/2/database_versioning/), but it ended up being pretty long, so I'll post a response here instead.

I'm the original author and current maintainer of the migrations plugin for datamapper. I spent a lot of time [thinking about AR migrations](http://www.theamazingrando.com/blog/?p=11) before I started writing it. I think that DM migrations have solved a few of the problems he has with AR migrations.

The part about screwing up a migration, and having to re-run it sounds more like a tooling problem. When I write a migration, I drop/create the db, and re-run all the migrations to 'test' it. (Also, the [DM migration specs](http://www.theamazingrando.com/blog/?p=21) should help with this.) Yeah, it blows away all your development data, but you should have fixtures or scripts or something to make it easy to recreate.

There are also long-term plans for a plugin in datamapper to inspect the current database schema, examine the definitions in the models, then "infer" the migration that needs to take place. It will be impossible, of course, to guess at what kind of data migration might be needed, but I believe that migrations shouldn't touch data. If, given your fullname => firstname, lastname example, I add the new columns, and run a rake task to handle the data. After a few days/weeks, when I'm sure that every production server has been upgraded, and that task run, I'll write a migration to drop the fullname column.

I do agree that having the database schema living in two different places if very non-dry, but even his suggestion of a schema.yml would duplicate the column definitions that are present in datamapper models.So

I've used these DM migrations in 2 projects now that have been in production for >6 months, and it fits in very well with my workflow. I tend to break up the migration files by table, so I end up with `schema/people.rb`, `schema/articles.rb`, `schema/comments.rb`, with each of those being a table in the db. Then inside one of the files, I list the migrations in version order: `1, :create_people_table`, `2, :add_firstname_lastname`, `3, :remove_fullname`. This lets me see at a glance what version I'm on for a particular table, and I don't have to worry about dependencies. If I do need to modify several tables at once, I have a simple rake task that tells me what the maximum version number is, so I can make one after it.

I think that tryring to use SHAs as version numbers would be even more annoying than epoch timestamps as versions. I do like the idea about the model/application requiring a specific version, and refusing to start otherwise. From a DataMapper POV, it would be easy to add a `#requires_db_version(5)` method to the model. I'm already in the habit of not using my models in migrations, by virtue of never writing data migrations. I even just usually write the migrations in raw SQL, it gives me more control over the table stucture when I really care.

So, essentially, DataMapper already provides the solution that Adam outlines in his post; Replace schema.yml with DataMapper model definitions, and have the discipline to not write data migrations. Write specs for your migrations, like everything else, and use DM migrations' sane versioning, rather than AR's irritating one, and you should be fine. There are definitely improvements to be made with DM migrations, to be sure, but I feel like I got the underlying design mostly right.
