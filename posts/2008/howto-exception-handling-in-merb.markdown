Title: HOWTO: Exception Handling in Merb

Our app is very (JSON) web-service heavy, and so having helpful error messages in our web service documents is pretty important. Luckily, Merb makes this, like everything, a metric shitton easier than it is in rails. There are a couple poorly documented things I had to stumble through, so I thought I would write some up on how to do this.

In Merb, if anything raises an exception, it looks for an action with the same name in the Exceptions controller. `merb-gen` gave you a simple one in `app/controllers/exception.rb`. Here's what mine looks like now:

`app/controllers/exceptions.rb`

    class Exceptions < Application
      provides :json                                                  # [1]
      
      # handle NotFound exceptions (404)
      def not_found
        return standard_error if content_type == :json                # [2]
        render
      end

      # handle NotAcceptable exceptions (406)
      def not_acceptable
        return standard_error if content_type == :json
        render
      end

      # handle NotAuthorized exceptions (403)
      def not_authorized
        return standard_error if content_type == :json
        render
      end

      # Everything else (500)
      def standard_error                                              # [3]
        # Re-Raise so we get the pretty merb error document instead.
        raise request.exceptions.first if content_type == :html       # [4]

        @exceptions = request.exceptions
        @show_details = Merb::Config[:exception_details]
        render :standard_error                                        # [5]
      end

    end

Some things to note about what I've done:

 1. Make sure it `#provides` for the web-service content-type.
 2. Since I just wanted to use the same view template for every error (see below), I had to explicitly make all web-service calls render that action instead. I could have just removed those methods and deleted the templates, but then any html views in the app would be generic, and I wanted custom ones for 403 and 404.
 3. Since all errors inherit from `StandardError`, this will catch everything.
 4. However, in the case of HTML documents, we want to use the fancy merb one, so re-raise the error so that merb's default error controller will handle it for us.
 5. Set up some variables to use in the view, then render that. *Be sure to include `:standard_error` so that the other error handlers know which template to render!*

And finally, here's what my view looks like. You can do whatever you want, of course. `#j` is just a global helper I have that basically does `#to_json` on whatever you give it, with some special cases for date formatting and indenting in dev vs production.

`app/views/exceptions/standard_error.json.erb`:

    <%= j( {
      :_type        => "InternalServerError",
      :request_uri  => request.env['REQUEST_URI'],
      :parameters   => params,
      :exceptions   => @exceptions.map do |exception|
        {
          :name       => exception.class,
          :message    => exception.message,
          :backtrace  => @show_details ? exception.backtrace : exception.backtrace.first.to_a
        }
      end
    } ) %>


