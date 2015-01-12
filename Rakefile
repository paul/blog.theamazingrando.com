require 'redcarpet'
require 'time'
require 'slim'
require 'sass'
require 'tilt'
require 'pathname'
require 'nokogiri'

MARKDOWN_OPTS = {
  no_intra_emphasis: true,
  fenced_code_blocks: true,
  lax_spacing: true,
  underline: true,
}

SLIM_OPTS = {
  pretty: true
}

class Post
  attr_reader :source_file

  def initialize(source_file)
    @source_file = source_file
  end

  def path
    filename = File.basename(source_file)
    filename, ext = filename.split('.')
    path = File.join(source_file.gsub(/\.#{ext}$/, ".html"))
  end

  def output_file
    output_path = File.join("output", path)
  end

  def parent_dir
    Pathname.new(output_file).dirname.to_s
  end

  def content_mkd
    File.open(source_file, 'r').read
  end

  def content_html
    template = Tilt.new(source_file, MARKDOWN_OPTS)
    template.render
  end
  alias render content_html

  def title
    h1 = doc.css("h1").first
    if h1
      h1.content
    else
      warn("please set the title on #{source_file}")
    end
  end

  def synopsis
    p = doc.css("p").first
    p ? p.content : ""
  end

  def doc
    @doc ||= Nokogiri::HTML(content_html)
  end

  def published_date
    published_date = Time.parse(`git log --reverse --pretty=format:"%ai" #{source_file} | head -1`)
  end

  def href
    path
  end
end

def render_post(post)
  layout = "templates/layout.html.slim"
  template = Tilt.new(layout)
  template.render(post) { post.render }
end

def render_index(posts)
  layout = "templates/layout.html.slim"
  template = Tilt.new(layout)
  index_template = Tilt.new("templates/index.html.slim")
  template.render(nil, title: "Index") do
    index_template.render(posts, posts: posts)
  end
end

def say_with_time(msg, &block)
  start = Time.now
  result = yield
  elapsed = Time.now - start
  puts "[%0.4fs] %s]" % [elapsed, msg]
  result
end

namespace :publish do

  desc "Publish everything in ./posts"
  task :all do
  end

end

directory "output/posts"

TEMPLATES = FileList['templates/**/*']

POSTS = FileList['posts/**/*.{md,mkd,markdown}'].map { |f| Post.new(f) }.sort_by(&:published_date).reverse

POSTS.each do |post|
  directory post.parent_dir

  file post.output_file => [post.source_file, *TEMPLATES, post.parent_dir, __FILE__] do
    say_with_time post.source_file do
      content = render_post(post)
      File.open(post.output_file, 'w+').write(content)
    end
  end
  task 'publish:all' => post.output_file
end

file "output/index.html" => ['templates/index.html.slim', 'templates/layout.html.slim', *POSTS.map(&:source_file), *TEMPLATES, __FILE__] do
  say_with_time "index.html" do
    content = render_index(POSTS)
    File.open("output/index.html", "w+").write(content)
  end
  task 'publish:all' => "output/index.html"
end

ASSETS = FileList['assets/**/*.{scss,coffee}']

ASSETS.each do |source|

  ext = source.split('.').last
  dest = File.join("output", source.gsub(/\.scss$/, ''))
  dirname = Pathname.new(dest).dirname.to_s

  directory dirname

  file dest => [source, dirname, __FILE__] do
    say_with_time source do
      template = Tilt.new(source)
      File.open(dest, 'w+').write(template.render)
    end
  end
  task 'publish:all' => dest

end

IMAGES = FileList['assets/**/*.{jpg,png,gif}']

IMAGES.each do |source|
  dest = File.join("output", source)
  dirname = Pathname.new(dest).dirname.to_s

  directory dirname

  file dest => [source, dirname, __FILE__] do
    say_with_time "#{source} => #{dest}" do
      cp source, dest
    end
  end
  task 'publish:all' => dest


end

