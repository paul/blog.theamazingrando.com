#Rails tip: Additional content for a layout

If you need to add additional content to your layout, you can have named content_for blocks. Great for including additional page-specific javascript files.

In application.erb:
<pre LANG="rails">
<!-- snip -->
<%= javascript_include_tag :defaults %>
<%= yield :javascript %>
<!-- snip --></pre>
Then inside your view, you can:
<pre LANG="rails">
<% content_for :javacript do %>
  <%= javascript_include_tag 'view-specific.js' %>
<% end %></pre>