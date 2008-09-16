Title: HOWTO: Getting a sidebar in Merb

In several of my pages, I have a side-bar menu-y thingie. I didn't want to have to rewrite a controller-specific layout each time, but luckily Merb supports something similar to [Rails's content_for][content_for] block that [I wrote about earlier][content_for blog post]. In Merb, its done using `throw_content`([API][throw_content]) and `catch_content`([API][catch_content]).

Put the `catch_content` into your application layout view. You probably already have `catch_content :for_layout` in there, by default. Here's what mine looks like:

    %html
      %head
        %meta{:'http-equiv' => 'content-type', 'content' => 'application/xhtml+xml; charset=UTF-8'}

        = css_include_tag "layout", "style"

        %title Page with Sidebar

      %body

        #side-bar
          = catch_content :sidebar

        #main
          = catch_content :for_layout

        #footer
          .left= copyright
          .right= last_modified

Using haml, I've put my sidebar in a `div` with id `#side-bar`.

Now in the view, add a `throw_content` for what you want in the sidebar. In my case, I'm using a partial that gets picked up out of the controller's view directory automatically.


    - throw_content(:sidebar, partial('sidebar'))

    %h1 This page has a sidebar


And ta-da! I only have to write the sidebar partial once for each controller, and I don't have to write an extra layout for each one. I have a fairly uncomplicated layout, and fill out the various parts of it by throwing rendered partials into it. 

[content_for]: http://api.rubyonrails.org/classes/ActionView/Helpers/CaptureHelper.html#M001751
[content_for blog post]: http://www.theamazingrando.com/blog/?p=7
[throw_content]: http://merb.rubyforge.org/classes/Merb/ViewContextMixin.html#M000146
[catch_content]: http://merb.rubyforge.org/classes/Merb/RenderMixin.html#M000129
