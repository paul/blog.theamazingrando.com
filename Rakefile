
desc "Build the site"
task :build do
  sh "middleman build"
end

desc "Deploy to s3"
task :deploy => :build do
  sh "middleman s3_sync"
end
