---
category: Tips & Tricks
tags:
 - Ruby
---

#HOWTO - Get a list of a class's subclasses


I recently came across a situation where I had an AbstractClass, an I wanted to know all of the classes that had inherited from it. There were lots of implementations on the web, but that weren't exactly what I wanted, or they used ObjectSpace to get ALL the classes, and see if the interesting one was in its ancestors.

I only needed it one-level deep, but it would be fairly easy to extend it for more.

    class ParentClass
      def self.subclasses
        @subclasses ||= Set.new
      end

      def self.inherited(subclass)
        subclasses << subclass
      end
    end

    class ChildA < ParentClass; end
    class ChildB < ParentClass; end

    ParentClass.subclasses
    # => #<Set: {ChildA, ChildB}>

