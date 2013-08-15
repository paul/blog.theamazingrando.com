require 'redcarpet'
require 'time'

def markdown
  @markdown ||=
    Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                            no_intra_emphasis: true,
                            fenced_code_blocks: true,
                            lax_spacing: true,
                            underline: true,
                           )
end

def render_file(file)
  content = File.open(file, 'r').read
  html    = markdown.render(content)

  if match = Regexp.new(/^Title: ([^\n]+)/ ).match(content)
    title = match[1]
  elsif match = Regexp.new(/^# ([^\n]+)/).match(content)
    title = match[1]
  else
    warn("please set the title on #{file}")
  end

  published_date = Time.parse(`git log -n1 --pretty=format:"%ai" #{file}`)

  html

end

namespace :publish do

  desc "Publish everything in ./posts"
  task :all do

  end

end

directory "output/posts"

POSTS = FileList['posts/**/*.{mkd,markdown}']

POSTS.each do |path|
  filename = File.basename(path)
  filename, ext = filename.split('.')
  output_path = File.join("output", path.gsub(/\.#{ext}$/, ".html"))

  file output_path => path do
    puts "#### #{path}"
    mkdir_p output_path.split('/')[0..-2].join('/')
    File.open(output_path, 'w+').write(render_file(path))
  end
  task 'publish:all' => output_path

end
