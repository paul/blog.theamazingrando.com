# frozen_string_literal: true

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

      first_draft_str = `git log --follow --pretty=format:"%ai" #{full_path} | tail -1`
      first_draft = first_draft_str.blank? ? Time.now : Time.parse(first_draft_str)

      updated_at_str = `git log --follow --pretty=format:"%ai" #{full_path} | head -1`
      updated_at = updated_at_str.blank? ? Time.now : Time.parse(updated_at_str)

      first_paragraph = doc.css("p").first

      content = doc.dup
      content.css("h1:first-of-type").remove

      {
        title: title,
        date: first_draft,
        first_draft_at: first_draft,
        updated_at: updated_at,
        first_paragraph: first_paragraph,
        content: content
      }
    end

    ::Middleman::Extensions.register(:git_matter, self)
  end
end
