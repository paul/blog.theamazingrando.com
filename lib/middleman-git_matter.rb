module Middleman::CoreExtensions
  class GitMatter < ::Middleman::Extension
    # Try to run after routing but before directory_indexes
    self.resource_list_manipulator_priority = 20


    def manipulate_resource_list(resources)
      resources.each do |resource|
        next if resource.binary?
        next if resource.file_descriptor.nil?
        next unless resource.content_type =~ %r{^text/html}
        next unless File.extname(resource.file_descriptor.full_path) == ".markdown"

        post_data = extract_data(resource)

        resource.add_metadata page: post_data
      end

    end

    protected

    def extract_data(resource)
      full_path = resource.file_descriptor[:full_path].to_s
      html_text = resource.render(layout: false)
      doc = Nokogiri::HTML(html_text)

      h1 = doc.css("h1").first
      title = if h1
                h1.content
              else
                warn("no h1 found in #{full_path}")
                "None"
              end

      published_date_str = `git log --follow --pretty=format:"%ai" #{full_path} | tail -1`
      published_date = published_date_str.blank? ? Time.now : Time.parse(published_date_str)

      first_paragraph = doc.css("p").first

      {
        title: title,
        date: published_date,
        first_paragraph: first_paragraph
      }
    end

    ::Middleman::Extensions.register(:git_matter, self)
  end
end

