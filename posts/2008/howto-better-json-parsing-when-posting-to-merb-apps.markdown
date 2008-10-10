Title: HOWTO: Better JSON parsing when POSTing to Merb Apps

Where I work, we have fairly extensive, JSON-based web services in all out applications. As a quick example, here's what you would get if you were to `GET` `http://config.ssbe.example.com/configurations/90` with the mime-type `application/vnd.absperf.sscj1+json`:

    {
      "_type":                      "Configuration",
      "href":                       "http://config.ssbe.localhost/configurations/90",
      "id":                         "4c5895f2-28a3-4299-a558-270889e6f065",
      "name":                       "lacquered",
      "notes":                      "Hosted hundredfold broomstick",
      "platform":                   "AIX",
      "client_href":                "http://core.ssbe.localhost/clients/jousting",
      "registered_templates_href":  "http://config.ssbe.localhost/configurations/90/registered_templates",
      "parent_configuration_href":  "http://config.ssbe.localhost/configurations/90",
      "created_at":                 "2008-10-07T16:38:29-06:00",
      "updated_at":                 "2008-10-08T15:20:51-06:00"
    }

I'm planning on a bigger post about exactly what our JSON document means, and our mime-types, and everything. For now, a good explaination of the reasoning behind our mime-types can be found [over on Peter's blog][VersioningRest].

That aside, now that I've `GET`ed this document, I'd love to be able to just string-manipulate the one or two things I want to modify, and just `PUT` it back where I got it, in the same format, with all the same attributes. The problem with that, though, is that several of these attributes are determined server-side, such as `_type`, `href`, and `id`. These values a set by the server, and a few of them aren't even properties on the model. I could throw an error back when someone tries to submit a value for an unchangeable attribute, but then I wouldn't be able to `POST` the identical document that I just `GET`ed. I'd have to know a fair amount about the document to know which attributes I have to remove from the document before I can give it back. I'd much prefer the server just ignore it. Now, I could throw an error if someone tries to *change* one of these attributes, but I'll save that for later. In any event, right now, I just want my controller to parse the JSON, and let it ignore the attributes I don't care about.

To that end, I implemented a custom JSON parser in a before filter in my Application controller:

    class Application < Merb::Controller
      before :parse_supplied_sscj1, :if => :has_sscj1_content         #[1]

      def has_sscj1_content
        request.content_type == 'application/vnd.absperf.sscj1+json'  #[2]
      end

      def parse_supplied_sscj1
        begin 
          jobj = JSON.parse(request.raw_post)                         #[3]
          raise UnprocessableEntity unless jobj.is_a?(Hash)           #[4]

          model_class = jobj["_type"].snake_case                      #[5]

          params[model_class] = jobj
        rescue JSON::ParserError => e
          raise BadRequest.new(e.message)                             #[6]
        end
      end
    end

A brief description of what all this means:

 1. Set up the before filter to do the parsing, but only under the right conditions.
 2. Those conditions are merely if somebody set the `Content-Type` header on the request to my `sscj1` mime-type.
 3. JSON parse the body of the request. Request#raw_post is how you get to the raw data that was `POST`ed (and `PUT`, too)
 4. I expect every JSON document i get to be parsed into a Hash object, so throw a standard HTTP error if its not.
 5. Because I have the `_type` attribute in my document, I can use that to put the parsed attributes in the right place. From the example above, I end up with `params = {"configuration" => {"name" => "lacquered", ...}, ...}`
 6. Oh, and if we got an invalid (unparseable) JSON document, raise a 400 Bad Request error.

So that takes care of the JSON parsing. Its a little better than the one built-in to merb, because of the error handling, and putting the attributes into a useable place in the form. Now, what do we do about the attributes we want to ignore? I added a couple class methods to Controller for handling that.

    class Application < Merb::Controller
      class << self
        attr_accessor :attributes_to_ignore

        def ignore_attributes(*attrs)
          @attributes_to_ignore = attrs
        end

      end

      def attributes_to_ignore
        %w[_type href id created_at updated_at] + self.class.attributes_to_ignore
      end

    end

    class Configurations < Application
      provides :sscj1

      ignore_attributes 'registered_templates_href'

      # ...
    end

This is all pretty simple. Essentially, I just added a `#ignore_attributes` class method to my controllers, so I can provide a list of attributes to be ignored, specific to each controller. The `#attributes_to_ignore` method lists the default ones, and in this case, I want my configurations to ignore `registered_templates_href` in addition to those. Now I can just delete those from the parsed JSON object in my `#parse_supplied_sscj1` method:

      attributes_to_ignore.each do |key|
        jobj.delete(key)
      end

Simple!

Now, I have that pesky `parent_configuration_href` attribute still coming in. I dont want to ignore it, but I do need a `parent_id` attribute in my configuration model, representing a self-referential join. To do that, I'd love to be able to run the given uri through merb's router and parse out the `id`, but unfortunetly, thats not part of the public API (yet). I'll just have to write my own simple regex parser to pull it out, and have a nice clever way to set that in my Configurations controller. So on to the code:

    class Application < Merb::Controller
      class << self
        attr_accessor :attributes_to_alter
        def alter_attribute(attribute, &block)
          @attributes_to_alter ||= {}
          @attributes_to_alter[attribute] = block
        end
      end
      def attributes_to_alter
        Merb.logger.info self.class.attributes_to_alter.inspect
        self.class.attributes_to_alter || {}
      end

    end

    class Configurations < Application
      provides :sscj1

      alter_attribute 'parent_configuration_href' do |_,uri|
        {'parent_id' => extract_configuration_id(uri)}
      end

      def self.extract_configuration_id(uri)
        return nil unless uri
        %r{/configurations/(\d+)}.match(uri)
        $1
      end

    end

So, here we have something similar to the `#ignore_attributes`, except now we have a block to be called on the attribute we want to change. In this case, I match the `configurations` part of the URI, and capture the `id`. Then , in my `#parse_supplied_sscj1` method, I replace the old value with the new one:

    def parse_supplied_sscj1
      begin 
        jobj = JSON.parse(request.raw_post)
        raise UnprocessableEntity unless jobj.is_a?(Hash)

        model_class = jobj["_type"].snake_case

        attributes_to_ignore.each do |key|
          jobj.delete(key)
        end

        attributes_to_alter.each do |attribute, block|
          new_attrs = block.call(attribute, jobj.delete(attribute))
          jobj.merge!(new_attrs)
        end

        params[model_class] = jobj
      rescue JSON::ParserError => e
        raise BadRequest.new(e.message)
      end
    end

Thats the entire method that I'm using right now. I hope to package this all up as a merb plugin soon, keep and eye on my github, and I'll probably post something about it here, soon.


[VersioningRest]: http://barelyenough.org/blog/2008/05/versioning-rest-web-services/
