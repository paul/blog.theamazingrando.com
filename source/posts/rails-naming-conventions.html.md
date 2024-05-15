# Rails File Naming Conventions

One of the best things about Rails, that it gets right over so many other frameworks like React, is its _Directory Naming Conventions_. You can jump into any Rails app written in the last 15 years and no immediately where to go to start exploring. Where's the routes? Database Models? Controllers and Views? Every app keeps them in the same place, so once you learn it, you can easily transfer that knowledge to another project.

That's for types of objects that come with Rails though (Models, Controllers, Jobs, etc...). Modern best-practices have a variety of extra Service Objects  like Queries, Adapters, Commands, and more. Where do you put those? Unfortunately, its not as clear.

This post represents my personal opinion on the subject, informed by my experiences since the early days, working on a number of different Rails apps, large and small. Even some subtle things can have a huge impact in developer happiness and friction. But, this is just like my opinion man, yours may differ, so feel free to steal my ideas and use the ones you like best.

Here's some general guidelines I try to follow:

## Avoid being too flat.

Too many directories and files under a single parent causes the tree view in editors and file browsers to scroll, making things hard to find.

## But also avoid being nested too deep.

All that hunting and clicking in a tree view is annoying, too.

## Keep the fuzzy-finder in mind.

One app I used had third-party API clients in a single folder under app, so for example `app/clients/salesforce.rb`. But whenever I wanted to open what my brain called the "Salesforce Client" I would type something like `sfcli` into my editor's fuzzy-finder, and it wouldn't find it. I never ever managed to remember on the first try that I had to type `clisf` instead.

## Group Service Objects by "business purpose" instead of "type".

Most apps I've seen that introduce Service Objects for the first time blindly follow the Rails pattern. It seems obvious, if models go in `app/models` and controllers go in `app/controllers`, then I should put my Queries in `app/queries`, right? However, I find that if you instead put Service Objects together by what they *do* instead of what they *are*, there's a number of advantages. 

Let's give an example:

```
app/  
├─ aspects/  
│　├─ authorization.rb  
│　└─ authorization/  
│　　　├─ auth0_client.rb  
│　　　├─ authenticate_user.rb  
│　　　├─ clean_stale_sessions_job.rb  
│　　　├─ handle_omniauth_callback.rb  
│　　　├─ signup_form.rb  
│　　　├─ stale_sessions_query.rb  
│　　　└─ verify_user_token.rb  
├─ controllers/  
│　└─ sessions_controller.rb  
├─ jobs/  
└─ models/  
　　├─ user.rb  
　　├─ account.rb  
　　└─ membership.rb
```

Here's a hypothetical layout for handling Authorization. I like to keep Models and Controllers in the Rails-standard locations, because Rails gets picky about the naming of them, and its because where newly-onboarded devs expect to look. 

Under `app`, I add a new top-level directly called `aspects`. I used to call this `components`, but if your app uses ViewComponent, it takes over `app/components` and things get confusing. `aspects` is shorter, but I'm not fully settled on this term yet. Each directory under here represents a "Business Aspect" of your application. Like in this case we have Authorization, but this could be like "Integrations", "Billing", "Admin", or "UserSettings". If you imagine an app like GMail's UI, we might have additional Aspects for "Inbox", "Filters" and "Attachments".

In this case, for our Authorization Aspect, we have an API Client (`auth0_client.rb`), some Commands (`authenticate_user.rb`, `handle_omniauth_callback.rb`), a FormObject (`signup_form.rb`), a Job (`clean_stale_sessions_job.rb`) and a Query (`stale_sessions_query.rb`).

I also create a top-level `authorization.rb`, which explicitly defines the `module Authorization` namespace. If you're using [Dry::Container](https://dry-rb.org/gems/dry-container/0.7), it also gives you a nice place to define a `Authorization::Container` and `AutoInject`.

Here's what I like about having things grouped together like this:

1. **Easy to find/fuzzy-find**. If I'm working on Authorization, I can expand the `app/aspects/authorization` folder in my tree view to see all the related files. I can type prefix all my fuzzy-finder searches with `auth` to quickly scope the search.
2. **Easier to cleanup**. I find this particular important for Queries. If we decide we don't need to cleanup sessions any more, we delete the `Authorization::CleanSessionsJob`. Since the `Authorization::StaleSessionsQuery` is right there with it, we have an indication of the scope, and know its safe to delete too. If it lived in `app/queries/stale_sessions.rb`, it would be much less obvious what code is using it, and if it was safe to delete. Additionally, especially in the early days of a startup, you're trying different things, some of which don't pan out. Its easy to `rm -rf app/aspects/salesforce_integration` to nuke the whole thing at once, instead of having to track down all the files and inevitably leaving leftovers scattered around.
4. **Easier to test.** I can run the tests for a single component all at once. If I do a bunch of refactorings to the Commands in `app/aspects/authorization`, I can run all the relevant tests with `rspec spec/aspects/authorization`. I don't have to wait for the entire suite to run, which speeds up the red/green cycle, nor do I have to pass `rspec` a bunch of different filenames, which is annoying when I'm moving or renaming files as part of the refactor.

I've been iterating on this pattern for several different jobs and applications, with various team sizes, and I'm pretty happy with the tradeoffs that come from structuring app code this way. I'm always curious to learn how others approach it, if you've got some unique ideas you really like, let me know!
