#!/usr/bin/env rackup
# frozen_string_literal: true

use Rack::ContentLength

app = Rack::Directory.new Dir.pwd + "/output"
run app
