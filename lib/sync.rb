
require 'rubygems'
require 'bundler'
Bundler.setup

require 'pp'

require 'postly'
require 'maruku'
require 'nokogiri'

Postly.config = './postly.yml'

class Postly::Post

  def self.find(args = {})
    conform get('/readposts', defaults.merge(args))
  end

end

site = Postly::Site.all.find { |s| s.url =~ /blog.theamazingrando.com$/ }
site_posts = Postly::Post.find(:site_id => site.id)
pp site_posts

Dir['posts/**/*.markdown'].each do |file|
  content = File.open(file, 'r').read

  html = Maruku.new(content).to_html
  title = Nokogiri::HTML(html).css('title').first.content
  puts title

  published_date = Time.now

end

