
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

Dir['posts/**/*.markdown'].each do |file|
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
                               :date => published_date)
  end
end

