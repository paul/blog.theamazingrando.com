#Application-wide Config loader for Merb Apps

I saw [this post by Stephen Bartholomew](http://www.stephenbartholomew.co.uk/2008/8/22/simple-application-wide-configuration-in-rails) and thought that it was a pretty neat idea, so I adapted it for Merb applications. Merb already has the `Merb::Config` for storing config options, so I just added the config options to that, rather than the AppConfig class used in Steve's post. That also greatly simplifies its implementation:

    require 'yaml'
    
    class AppConfig  
      def self.load
        config_file = File.join(Merb.root, "config", "application.yml")
    
        if File.exists?(config_file)
          config = YAML.load(File.read(config_file))[Merb.environment]
    
          config.keys.each do |key|
            Merb::Config[key.to_sym] = config[key]
          end
        end
      end
    end

Put that in `lib/app_config.rb`. Then, anywhere in `config/init.rb`, add:

    Merb::BootLoader.after_app_loads do
      require 'app_config'
      AppConfig.load
    end

Finally, add your config options to `config/application.yml`, using the same `development`, `production`, etc environment keys as in the `database.yml`. I use it to keep the connection params for a couple non-RDBMS [DataMapper](http://datamapper.org) adapters I've written.


