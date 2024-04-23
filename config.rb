# frozen_string_literal: true

require "nokogiri"

require "lib/middleman-git_matter"
activate :git_matter

require "lib/middleman-categories"
activate :categories

# https://github.com/Aupajo/middleman-search_engine_sitemap
# You can override the priority or change frequency for a particular page by using frontmatter:

# ---
# title: Blog
# priority: 1.0
# change_frequency: daily
# ---
set :url_root, "http://blog.theamazingrando.com"
activate :search_engine_sitemap, default_priority: 0.5,
                                 default_change_frequency: "monthly"

activate :meta_tags

ignore "posts/.obsidian/*"

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page "/*.xml", layout: false
page "/*.json", layout: false
page "/*.txt", layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

###
# Helpers
###

activate :blog do |blog|
  blog.permalink = "posts/{title}.html"
  # This will add a prefix to all links, template references and source paths
  # blog.prefix = "/"

  blog.layout = "article"
  # blog.permalink = "{year}/{month}/{day}/{title}.html"
  # Matcher for blog source files
  blog.sources = "posts/{title}.html"
  blog.taglink = "tagged/{tag}.html"
  # blog.layout = "layout"
  # blog.summary_separator = /(READMORE)/
  # blog.summary_length = 250
  # blog.year_link = "{year}.html"
  # blog.month_link = "{year}/{month}.html"
  # blog.day_link = "{year}/{month}/{day}.html"
  # blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  # blog.calendar_template = "calendar.html"

  blog.custom_collections = {
    category: {
      link: "/categories/{category}.html",
      template: "/category.html"
    }
  }
  # Enable pagination
  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/{num}"
end

set :markdown_engine, :redcarpet
set :markdown, tables: true, fenced_code_blocks: true, autolink: true
activate :syntax

page "/feed.xml", layout: false
# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Methods defined in the helpers block are available in templates
helpers do
  def time_element(date)
    content_tag(:time, datetime: date.iso8601) do
      date.strftime("%A, %B #{date.day.ordinalize} %Y")
    end
  end

  GITHUB_ROOT = "https://github.com/paul/blog.theamazingrando.com/blob/master/"
  def github_source(resource)
    path = Pathname(resource.source_file).relative_path_from(File.dirname(__FILE__))
    GITHUB_ROOT + path.to_s
  end
end

# Build-specific configuration
activate :gzip
configure :build do
  # Minify CSS on build
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript
end

# activate :s3_sync do |s3_sync|
#   s3_sync.bucket                     = "blog.theamazingrando.com" # The name of the S3 bucket you are targeting. This is globally unique.
#   s3_sync.region                     = "us-east-1" # The AWS region for your bucket.
#   # s3_sync.aws_access_key_id          = 'AWS KEY ID'
#   # s3_sync.aws_secret_access_key      = 'AWS SECRET KEY'
#   s3_sync.delete                     = false # We delete stray files by default.
#   s3_sync.after_build                = false # We do not chain after the build step by default.
#   s3_sync.prefer_gzip                = true
#   s3_sync.path_style                 = true
#   s3_sync.reduced_redundancy_storage = false
#   s3_sync.acl                        = "public-read"
#   s3_sync.encryption                 = false
#   s3_sync.prefix                     = ""
#   s3_sync.prefer_gzip                = true
#   s3_sync.version_bucket             = false
#   s3_sync.index_document             = "index.html"
#   s3_sync.error_document             = "404.html"
# end
