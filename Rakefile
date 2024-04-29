# frozen_string_literal: true

desc "Build the site"
task :build do
  sh "middleman build"
end

desc "Publish to resume.sadauskas.com"
task :publish do
  FileUtils.cd "build" do
    `git commit -am "Re-render" && git push`
  end
end
