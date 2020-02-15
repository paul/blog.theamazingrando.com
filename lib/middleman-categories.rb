# frozen_string_literal: true

module Middleman::CoreExtensions
  class Categories < ::Middleman::Extension
    helpers do
      def categories(articles)
        articles.group_by { |a| a.data["category"] }.sort
      end
    end

    ::Middleman::Extensions.register(:categories, self)
  end
end
