
require 'rubygems'
require 'bundler'
Bundler.setup

require 'nokogiri'
require 'time'
require 'git'

import_file = File.expand_path(File.dirname(__FILE__) + '/../incoming/wordpress.2010-06-30.xml')
doc = Nokogiri::XML(File.read(import_file))

repo = Git.open('.')

doc.xpath('/rss/channel/item').sort_by { |item|
  Time.parse(item.xpath('wp:post_date').first.content)
}.each do |item|
  next unless item.xpath('wp:post_type').first.content == "post"

  title = item.xpath('title').first.content
  post_date = Time.parse(item.xpath('wp:post_date').first.content).utc
  content = item.xpath('content:encoded').first.content

  path = "posts/#{post_date.year}"
  safe_title = title.gsub(' ', '-').gsub(/[^a-zA-Z0-9_-]/, '').downcase
  filename = "#{safe_title}.markdown"
  file = File.join(path, filename)

  content = "\n##{title}\n\n#{content}"

  ENV['GIT_AUTHOR_DATE']   = post_date.iso8601
  ENV['GIT_COMMITER_DATE'] = post_date.iso8601

  `git checkout -b #{safe_title}`

  FileUtils.mkdir_p(path)
  File.open(file, 'w') do |f|
    f.write(content)
  end

  `git add #{file}`
  `git commit -m '#{title}'`
  `git checkout master`
  `git merge #{safe_title} --no-ff`
  `git branch -d #{safe_title}`

end

