
require 'rubygems'
require 'bundler'
Bundler.setup

require 'postly'
require 'maruku'
require 'nokogiri'
require 'active_support/core_ext/array/wrap'

Postly.config = './postly.yml'

class Postly::Post

  def self.find(args = {})
    conform get('/readposts', defaults.merge(args))
  end

  def self.update(post_id, params = {})
    opts = defaults.merge(:query => {:post_id => post_id}, :body => params)
    conform post("/updatepost", opts)
  end

  def self.create(params = {})
    conform post("/newpost", defaults.merge(:body => params))
  end


end

site = Postly::Site.all.find { |s| s.url =~ /blog.theamazingrando.com$/ }
site_posts = Postly::Post.find(:site_id => site.id)

file = ARGV[0]
raise "Please pass the file to post as the first argument" unless File.exist?(file)

content = File.open(file, 'r').read
html = Maruku.new(content).to_html

if match = Regexp.new(/^Title: ([^\n]+)/ ).match(content)
title = match[1]
else
warn("please set the title on #{file}")
end

published_date = Time.parse(`git log -n1 --pretty=format:"%ai" #{file}`)

post = Array.wrap(site_posts).find { |post|
post.title == title
}
if post
puts "Updating '#{title}'"
post = Postly::Post.update(post.id, :title => title, :body => html)
else
puts "Creating '#{title}'"
post = Postly::Post.create(:site_id => site.id,
                            :title => title,
                            :body => html,
                            :private => true,
                            :date => published_date)
end


