---
category: HowTo
tags:
 - Ruby
 - DataMapper
---

#HOWTO: DataMapper - Setting the default repository for a model

Had to google for quite a while before I was able to find the solution. Essentially, I have a model that I want to always use a different repository than what I `#setup` in `:default`. To do that:

    class Person
      include DataMapper::Resource

      def self.default_repository_name
        :other
      end

      property :name, String
    # ...
    end

This will make `Person.all` and all other queries use the `:other` repository, without having to use the `#repository(:other) { }` block.

