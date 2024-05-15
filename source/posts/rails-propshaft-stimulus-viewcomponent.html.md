---
category: Tips & Tricks
tags:
  - Rails
---

# Referencing Stimulus Controllers as ViewComponent Sidecar Files with Propshaft Importmaps

_AKA: How many Rails buzzwords can I fit in a single blog post title?_

In a [previous post](rails-naming-conventions.html), I described how I like to group related "Business Concept" objects together in `app/aspects`, rather than grouping them by type (`app/jobs`, `app/commands`, etc...)

In a [sideproject I'm working on](https://scalar.sh), I wanted to put my ViewComponent objects in that folder too, instead of `app/components`. Starting in ViewComponent 3, they support ["sidecar" files](https://viewcomponent.org/guide/templates.html#subdirectory), where you can put all the related files to that component in a subdirectory named the same as the component. Since I'm also using Stimulus for this project, and several of my Components have corresponding Stimulus controllers, I also wanted to put the controller.js file in that sidecar subdir, too.

For the final buzzword bingo, I'm _also_ using Propshaft for this project, as I [described in the last post](rails-7-propshaft-fonts.html). However, Propshaft only wants to look in the `app/assets` folder for Javascript controllers. I found [a](https://github.com/rails/propshaft/issues/87#issuecomment-1127234248) [few](https://github.com/ViewComponent/view_component/issues/1064#issuecomment-917760377) [different](https://github.com/ViewComponent/view_component/issues/1064#issuecomment-1046123018) [solutions](https://github.com/ViewComponent/view_component/issues/1064#issuecomment-1641212454), but none of them worked as-is, I had to cobble a few different solutions together. 

To get started, here's what one of my "aspects" folder looks like:

```
$ tree app/aspects/scalers
app/aspects/scalers
├── form_component
│   ├── component_controller.js
│   └── form_component.html.haml
├── form_component.rb
├── target_form_component
│   ├── component_controller.js
│   └── target_form_component.html.haml
└── target_form_component.rb
```

I have two components, `Scalers::FormComponent` and `Scalers::TargetFormComponent` (one is a sub-form of the main, keep an eye out for an upcoming block post about that!). 

First, I added the folders to the `config/initializers/assets.rb`:

```diff
diff --git a/config/initializers/assets.rb b/config/initializers/assets.rb
index b649f68..5311092 100644
--- a/config/initializers/assets.rb
+++ b/config/initializers/assets.rb
@@ -8,3 +8,10 @@ Rails.application.config.assets.version = "1.0"
 # Add additional assets to the asset load path.
 # Rails.application.config.assets.paths << Emoji.images_path
 # Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")
+Rails.application.config.assets.paths << "app/components"
+Rails.application.config.assets.paths << "app/aspects"
+
+Rails.application.config.importmap.cache_sweepers << Rails.root.join("app/components")
+Rails.application.config.importmap.cache_sweepers << Rails.root.join("app/aspects")
```

(I don't know if the "cache_sweepers" part is needed, I haven't deleted a stimulus controller in the project yet. It doesn't seem to hurt either.)

Then in my `config/importmap.rb`, I added those folders as controllers:

```diff
+pin_all_from "app/components", under: "controllers", to: ""
+pin_all_from "app/aspects", under: "controllers", to: ""
```

Finally, to reference this controller, you have to use the awkward naming scheme of replacing the `/` with `--` in the name. In my case, the `<form>` element I want to attach to the controller starts like this:

```html
<form data-controller="scalers--form-component--component" ...>
```

I don't actually write that out by hand. My controllers include a module that handles all the Stimulus naming for me (another upcoming post). Here's one of the helper methods:

```ruby
def stimulus_controller
  "#{self.class.name.underscore.dasherize.gsub('/', '--')}--component"
end
```

This wasn't hard to get working, it was just fiddly to figure out which parts of the different solutions I needed.