---
category: Tips & Tricks
tags:
  - Rails
---

# Using Local Font Files in the Rails 7.1 Asset Pipeline

I wanted to play with the new hotness of Rails asset handling in a sideproject, and ran into some fiddliness in getting FontAwesome webfonts to be seen when loading them from an SCSS file. I'm using [propshaft](https://github.com/rails/propshaft) and [Dart Sass](https://github.com/rails/dartsass-rails)

I happen to have a FontAwesome 5 Pro license from back when it was a KickStarter lifetime license, so that's what I'm using. FontAwesome 6 Pro is now a [$100/yr subscription](https://fontawesome.com/plans), which doesn't make sense for random side-projects, but I imagine these instructions will work the same. They provide a gem, but it wasn't working out-of-the-box for me in the new Rails asset pipeline, and I try to avoid dependencies when possible, so I installed it manually.

I started by [downloading the zipfile](https://fontawesome.com/download). It includes a bunch of stuff, but we only care about what's in `scss` and `webfonts`.

![FontAwesome Zip Contents](rails-7-propshaft-fonts/FontAwesome Zip.png)

I copied everything from `scss` into `app/assets/stylesheets/fontawesome`, and the font files from `webfonts` into `app/assets/fonts`. I noticed in FontAweseom6, it only includes files for `ttf` and `woff2`, since the other formats are for older browsers, so I only copied those.

![FontAwesome app assets folder](rails-7-propshaft-fonts/app-assets.png)

Then, in my `application.scss`, I added the main fontawesome file, and then the `regular` theme, since that's what I'm using.

```scss
// app/assets/stylesheets/application.scss
@use 'fontawesome/fontawesome';
@use 'fontawesome/regular';
```

I also had to modify the `fontawesome/regular.scss` file, to use the right asset paths for the font files. (The `regular.scss` from FontAwesome 5 is different than this, and I was struggling to get it working. This one is based off the [`regular.scss` from FontAwesome 6](https://github.com/FortAwesome/font-awesome-sass/blob/master/assets/stylesheets/font-awesome/_regular.scss)).

```scss
// app/assets/stylesheets/fontawesome/regular.scss
@import 'variables';

:root, :host {
  --fa-style-family-classic: "Font Awesome 5 Pro";
  --fa-font-regular: normal 400 1em/1 "Font Awesome 5 Pro";
}

@font-face {
  font-family: "Font Awesome 5 Pro";
  font-style: normal;
  font-weight: 400;
  font-display: block;
  // This here is the part to change
  src: url("fa-regular-400.woff2") format("woff2"), url("fa-regular-400.ttf") format("truetype");
}

.far,
.fa-regular {
  font-family: 'Font Awesome 5 Pro';
  font-weight: 400;
}
```

The important part I had to change was the `src: url(...)` bits. The way the asset pipeline works, these `url()` statements get replaced with the path to the digest files with the `/assets/` prefix.

![CSS Output](rails-7-propshaft-fonts/regular-css-output.png)

And with that, I get FontAwesome icons!

```haml
%a.is-active{href: dashboard_path(account_slug: params[:account_slug])}
  %span.icon
    %i.far.fa-tachometer-alt
	%span
	  Dashboard
```

![Menu icons screenshot](rails-7-propshaft-fonts/Menu-icons.png)
