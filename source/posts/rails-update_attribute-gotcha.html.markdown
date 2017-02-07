---
category: Tips & Tricks
tags:
 - Rails
---

#Rails update_attribute gotcha

Model#update_attribute(:name, "Rando") does not trigger any validations, <em>even on name</em> and just saves it to the database.

Model#update_attribute<strong>s</strong>(:name => "Rando") does run all validations, and returns false if they fail.

<a href="http://caboo.se/doc/classes/ActiveRecord/Base.html#M005871">Rails docs</a>
